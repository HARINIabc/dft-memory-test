// counter_wrapper_tb : self-checking testbench for counter_wrapper.
// Plain Verilog. The counter is tested only through the wrapper; the
// testbench never reads or writes anything inside u_core.
//
//   run :  iverilog -o wtb ../counter.v wbr_cell.v counter_wrapper.v counter_wrapper_tb.v
//          vvp wtb +seed=7
//   last line printed is "WRAPPER TB PASS: ..." or "WRAPPER TB FAIL: ..."
//
// Sections
//   T1 functional mode (WS_BYPASS after wrstn): the wrapper is transparent
//   T2 WIR shift/readback, WBY one-flop bypass path
//   T3 WBR chain integrity (flush) in INTEST and EXTEST
//   T4 INTEST directed: reset, count, hold, reset mid-count, 255->0 wrap
//   T5 INTEST random sequences against a reference model (seeded)
//   T6 EXTEST: wrapper drives count pins, captures rst_n/en pins, core isolated
//
//   +intest_only runs T4 and T5 alone, so the core is reached only through
//   the wrapper (used by the fault campaign).
module counter_wrapper_tb;
    localparam WS_BYPASS = 2'b00, WS_INTEST = 2'b01, WS_EXTEST = 2'b10;
    localparam NWBR = 10;

    reg clk = 0, rst_n = 0, en = 0;
    reg wrck = 0, wrstn = 0, selectwir = 0, shiftwr = 0, capturewr = 0, updatewr = 0, wsi = 0;
    wire [7:0] count;
    wire wso;

    counter_wrapper dut (
        .clk(clk), .rst_n(rst_n), .en(en), .count(count),
        .wrck(wrck), .wrstn(wrstn), .selectwir(selectwir), .shiftwr(shiftwr),
        .capturewr(capturewr), .updatewr(updatewr), .wsi(wsi), .wso(wso)
    );

`ifdef FAULT_NET
    // used only by the fault campaign (fault/run_faults.sh)
    initial force dut.u_core.`FAULT_NET = `FAULT_VAL;
`endif

    integer errors = 0, checks = 0, seed = 1, seed0;
    reg     intest_only;           // +intest_only: run T4 and T5 alone
    integer n_wrck = 0, n_clk = 0;
    integer i, k, nclk;
    reg [7:0] model;               // reference model of the core's count
    reg       model_valid;         // false until a reset has been applied
    reg [NWBR-1:0] vin, vout, va, vb;
    reg r_rst, r_en;

    // ---------------- low-level wrapper operations ----------------
    task pulse_wrck;  begin #5 wrck = 1; #5 wrck = 0; n_wrck = n_wrck + 1; end endtask

    // core clock pulse; the model follows whatever the core is being fed
    task pulse_clk(input in_rst, input in_en);
        begin
            #5 clk = 1;
            if (!in_rst)    begin model = 8'd0; model_valid = 1; end
            else if (in_en)  model = model + 8'd1;
            #5 clk = 0;
            n_clk = n_clk + 1;
        end
    endtask

    task load_wir(input [1:0] code);
        begin
            selectwir = 1; shiftwr = 1;
            wsi = code[0]; pulse_wrck;
            wsi = code[1]; pulse_wrck;
            shiftwr = 0; updatewr = 1; pulse_wrck;
            updatewr = 0; selectwir = 0;
        end
    endtask

    // shift a full WBR vector in (cell 9 bit first) and return what came out
    task shift_wbr(input [NWBR-1:0] in, output [NWBR-1:0] out);
        integer j;
        begin
            shiftwr = 1;
            for (j = NWBR-1; j >= 0; j = j - 1) begin
                wsi = in[j];
                #1 out[j] = wso;
                pulse_wrck;
            end
            shiftwr = 0;
        end
    endtask

    task update_wbr;  begin updatewr  = 1; pulse_wrck; updatewr  = 0; end endtask
    task capture_wbr; begin capturewr = 1; pulse_wrck; capturewr = 0; end endtask

    task check(input [255:0] what, input [31:0] got, input [31:0] exp);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("  ERROR %0s: got %h expected %h (t=%0t)", what, got, exp, $time);
            end
        end
    endtask

    // ---------------- INTEST: apply inputs, clock, capture, compare ----------
    task intest_apply(input t_rst, input t_en, input integer ncycles);
        integer c;
        reg [NWBR-1:0] junk, got;
        begin
            shift_wbr({8'h00, t_en, t_rst}, junk);
            update_wbr;
            for (c = 0; c < ncycles; c = c + 1) pulse_clk(t_rst, t_en);
            capture_wbr;
            shift_wbr({NWBR{1'b0}}, got);
            if (model_valid) check("INTEST count", got[NWBR-1:2], model);
        end
    endtask

    initial begin
        if (!$value$plusargs("seed=%d", seed)) seed = 1;
        seed0 = seed;
        intest_only = $test$plusargs("intest_only");
        $display("counter_wrapper_tb: seed=%0d", seed);
        model = 8'd0; model_valid = 0;

        // ---- reset the wrapper: WS_BYPASS, functional mode ----
        #12 wrstn = 1;

        if (!intest_only) begin
        // ---- T1 functional mode is transparent ----
        rst_n = 0; en = 1; pulse_clk(0, 1);
        check("T1 reset", count, model);
        rst_n = 1; en = 1;
        for (i = 0; i < 6; i = i + 1) pulse_clk(1, 1);
        check("T1 count", count, model);
        en = 0;
        for (i = 0; i < 4; i = i + 1) pulse_clk(1, 0);
        check("T1 hold", count, model);

        // ---- T2 WIR readback and bypass ----
        load_wir(WS_INTEST);
        selectwir = 1; shiftwr = 1;
        wsi = 0; #1 va[0] = wso; pulse_wrck;
        wsi = 0; #1 va[1] = wso; pulse_wrck;
        shiftwr = 0; selectwir = 0;
        check("T2 WIR readback", va[1:0], WS_INTEST);
        load_wir(WS_BYPASS);
        shiftwr = 1; wsi = 1; pulse_wrck;         // WBY now holds 1
        for (i = 0; i < 8; i = i + 1) begin
            k = $random(seed) & 1;
            wsi = k[0];
            #1 check("T2 WBY", wso, (i == 0) ? 1 : vb[0]);
            vb[0] = k[0];
            pulse_wrck;
        end
        shiftwr = 0;

        // ---- T3 WBR flush in INTEST and EXTEST ----
        load_wir(WS_INTEST);
        va = $random(seed); vb = $random(seed);
        shift_wbr(va, vout); shift_wbr(vb, vout);
        check("T3 flush INTEST", vout, va);
        load_wir(WS_EXTEST);
        shift_wbr(vb, vout); shift_wbr(va, vout);
        check("T3 flush EXTEST", vout, vb);

        end // !intest_only

        // ---- T4 INTEST directed ----
        load_wir(WS_INTEST);
        model_valid = 0;
        intest_apply(0, 1, 1);        // reset wins over en
        intest_apply(0, 0, 1);
        intest_apply(1, 1, 5);        // count to 5
        intest_apply(1, 0, 7);        // hold at 5
        intest_apply(1, 1, 3);        // 8
        intest_apply(0, 1, 1);        // reset in the middle of counting
        intest_apply(1, 1, 255);      // 255: every bit has risen
        intest_apply(1, 1, 1);        // 255 -> 0: every bit falls
        for (i = 0; i < 8; i = i + 1)  // walk through 1,2,4,...,128
            intest_apply(1, 1, (1 << i) - ((i == 0) ? 0 : (1 << (i-1))));

        // ---- T5 INTEST random ----
        for (i = 0; i < 300; i = i + 1) begin
            k     = $random(seed);
            r_rst = ((k & 7) != 0);              // reset about 1 time in 8
            r_en  = k[3];
            nclk  = ($random(seed) & 32'h7fffffff) % 41;   // 0..40 clocks
            intest_apply(r_rst, r_en, nclk);
        end

        // ---- T6 EXTEST ----
        if (!intest_only) begin
        load_wir(WS_EXTEST);
        for (i = 0; i < 20; i = i + 1) begin
            va = $random(seed);
            shift_wbr(va, vout);
            update_wbr;
            #1 check("T6 drive count pins", count, va[NWBR-1:2]);
            k = $random(seed);
            rst_n = k[0]; en = k[1];
            capture_wbr;
            shift_wbr({NWBR{1'b0}}, vout);
            check("T6 capture rst_n/en pins", vout[1:0], {k[1], k[0]});
        end
        end // !intest_only

        // ---- summary ----
        if (errors == 0)
            $display("WRAPPER TB PASS: %0d checks, 0 errors (seed %0d, %0d wrck + %0d clk cycles)",
                     checks, seed0, n_wrck, n_clk);
        else
            $display("WRAPPER TB FAIL: %0d checks, %0d errors (seed %0d)", checks, errors, seed0);
        $finish;
    end

    initial begin #20000000 $display("WRAPPER TB FAIL: timeout"); $finish; end
endmodule
