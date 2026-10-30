// wbr_cell : one IEEE 1500-style wrapper boundary register cell.
//
//              +-----------+        +-----------+
//   si ------->| shift ff  |------->| update ff |---+
//   cfi --+--->| (sff)     |   so   | (uff)     |   |
//         |    +-----------+        +-----------+   |
//         |                                         v
//         +-------------------------------------->|0\
//                                                 |  |---> cfo
//                                     mode ------>|1/
//
//   cfi  : the functional value arriving at this cell
//   cfo  : the value passed on (cfi in normal use, uff in test)
//   shift   : sff <= si   (one bit along the chain per wrck)
//   capture : sff <= cfi  (snapshot of the functional value)
//   update  : uff <= sff  (apply the shifted-in value; uff holds it steady
//                          while the chain shifts, so cfo never ripples)
//
// The same cell is used on both sides of the core:
//   input cell  : cfi = wrapper pin, cfo = core input,  mode = INTEST
//   output cell : cfi = core output, cfo = wrapper pin, mode = EXTEST
module wbr_cell (
    input      wrck,
    input      wrstn,
    input      si,
    output     so,
    input      cfi,
    output     cfo,
    input      shift,
    input      capture,
    input      update,
    input      mode
);
    reg sff, uff;

    always @(posedge wrck or negedge wrstn) begin
        if (!wrstn)       sff <= 1'b0;
        else if (shift)   sff <= si;
        else if (capture) sff <= cfi;
    end

    always @(posedge wrck or negedge wrstn) begin
        if (!wrstn)       uff <= 1'b0;
        else if (update)  uff <= sff;
    end

    assign so  = sff;
    assign cfo = mode ? uff : cfi;
endmodule
