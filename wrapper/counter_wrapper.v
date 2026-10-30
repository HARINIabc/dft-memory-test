// counter_wrapper : IEEE 1500-style test wrapper around counter, which is
// treated as a black box. Nothing inside counter.v is changed or looked at;
// every test goes through its pins.
//
//  Wrapper Serial Port (WSP)
//    wrck      wrapper clock (shift/capture/update all happen on its edge)
//    wrstn     wrapper reset, active low; puts the wrapper in WS_BYPASS,
//              which is normal functional mode
//    selectwir 1 = the WIR is between wsi and wso, 0 = the instruction's
//              data register is (WBR or WBY)
//    shiftwr / capturewr / updatewr   the three operations, one per wrck
//    wsi / wso serial in / out
//
//  Instructions (2-bit WIR)
//    2'b00 WS_BYPASS  core runs normally from the wrapper pins; WBY (1 flop)
//                     is between wsi and wso
//    2'b01 WS_INTEST  core inputs come from the WBR input cells; the WBR
//                     output cells capture the core outputs. Tests the core.
//    2'b10 WS_EXTEST  wrapper output pins are driven from the WBR output
//                     cells; WBR input cells capture the wrapper input pins.
//                     Tests the logic and wiring around the core.
//    2'b11 reserved   decodes as WS_BYPASS
//
//  WBR order (wsi side first):
//    cell 0 = rst_n (in), cell 1 = en (in), cells 2..9 = count[0..7] (out)
//
//  Clocks: clk (core) and wrck (wrapper) are both primary inputs, and no
//  clock is generated or gated in this RTL. In INTEST the tester stops clk
//  while it shifts on wrck, then applies clk pulses to run the core.
module counter_wrapper (
    // functional pins, same as counter
    input        clk,
    input        rst_n,
    input        en,
    output [7:0] count,
    // wrapper serial port
    input        wrck,
    input        wrstn,
    input        selectwir,
    input        shiftwr,
    input        capturewr,
    input        updatewr,
    input        wsi,
    output       wso
);
    localparam WS_BYPASS = 2'b00, WS_INTEST = 2'b01, WS_EXTEST = 2'b10;
    localparam NIN = 2, NOUT = 8, NWBR = NIN + NOUT;

    // ---------------- WIR ----------------
    reg [1:0] wir_s, wir_u;
    always @(posedge wrck or negedge wrstn) begin
        if (!wrstn) begin
            wir_s <= WS_BYPASS;
            wir_u <= WS_BYPASS;
        end else if (selectwir) begin
            if (shiftwr)        wir_s <= {wsi, wir_s[1]};
            else if (updatewr)  wir_u <= wir_s;
        end
    end

    wire intest  = (wir_u == WS_INTEST);
    wire extest  = (wir_u == WS_EXTEST);
    wire wbr_sel = !selectwir && (intest || extest);
    wire wby_sel = !selectwir && !(intest || extest);

    // ---------------- WBY ----------------
    reg wby;
    always @(posedge wrck or negedge wrstn) begin
        if (!wrstn)                 wby <= 1'b0;
        else if (wby_sel && shiftwr) wby <= wsi;
    end

    // ---------------- WBR ----------------
    wire [NWBR:0]   chain;           // chain[i] feeds cell i, chain[NWBR] is out
    wire [NIN-1:0]  pin_in   = {en, rst_n};
    wire [NIN-1:0]  core_in;
    wire [NOUT-1:0] core_out;
    assign chain[0] = wsi;

    wire wbr_shift   = wbr_sel && shiftwr;
    wire wbr_capture = wbr_sel && capturewr;
    wire wbr_update  = wbr_sel && updatewr;

    genvar i;
    generate
        for (i = 0; i < NIN; i = i + 1) begin : g_in
            wbr_cell u_cell (
                .wrck(wrck), .wrstn(wrstn),
                .si(chain[i]), .so(chain[i+1]),
                .cfi(pin_in[i]), .cfo(core_in[i]),
                .shift(wbr_shift), .capture(wbr_capture), .update(wbr_update),
                .mode(intest)
            );
        end
        for (i = 0; i < NOUT; i = i + 1) begin : g_out
            wbr_cell u_cell (
                .wrck(wrck), .wrstn(wrstn),
                .si(chain[NIN+i]), .so(chain[NIN+i+1]),
                .cfi(core_out[i]), .cfo(count[i]),
                .shift(wbr_shift), .capture(wbr_capture), .update(wbr_update),
                .mode(extest)
            );
        end
    endgenerate

    // ---------------- the black box ----------------
    counter u_core (
        .clk  (clk),
        .rst_n(core_in[0]),
        .en   (core_in[1]),
        .count(core_out)
    );

    // ---------------- serial out ----------------
    assign wso = selectwir ? wir_s[0]
               : wbr_sel   ? chain[NWBR]
               :             wby;
endmodule
