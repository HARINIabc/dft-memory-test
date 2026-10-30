// sram : 16x8 behavioural memory model with an optional stuck-at-0 cell fault.
//
// Recreated on 2026-10-30. The original sram.v was never committed, so the
// README's run command failed. This version was rebuilt from the compiled
// mbist_sim in the repo (same ports, same parameters and defaults, same
// behaviour), and reproduces the README's expected output.
//
//   write : synchronous, on posedge clk when we=1
//   read  : asynchronous, dout follows addr in the same cycle
//   fault : when FAULT_EN=1, bit FAULT_BIT of word FAULT_ADDR always reads 0
//           (a stuck-at-0 storage cell, modelled at the read port)
module sram #(
    parameter AW = 4,
    parameter DW = 8,
    parameter FAULT_EN   = 0,
    parameter FAULT_ADDR = 5,
    parameter FAULT_BIT  = 3
) (
    input               clk,
    input               we,
    input  [AW-1:0]     addr,
    input  [DW-1:0]     din,
    output [DW-1:0]     dout
);
    reg  [DW-1:0] mem [0:(1<<AW)-1];
    wire [DW-1:0] raw = mem[addr];

    always @(posedge clk)
        if (we) mem[addr] <= din;

    assign dout = (FAULT_EN && addr == FAULT_ADDR)
                ? (raw & ~({{(DW-1){1'b0}}, 1'b1} << FAULT_BIT))
                : raw;
endmodule
