module mbist #(parameter AW=4, DW=8)
(
    input clk, rst_n, start,
    output reg done, fail,
    output [AW-1:0] addr_o,
    output we,
    output [DW-1:0] wdata,
    input  [DW-1:0] rdata
);
    localparam MAX = (1<<AW)-1;
    localparam IDLE=0, RUN=1, FIN=2;
    reg [1:0] state;
    reg [2:0] elem;
    reg       phase;
    reg [AW-1:0] addr;

    wire up        = (elem <= 2);
    wire has_write = (elem != 5);
    wire exp1      = (elem == 2 || elem == 4);
    wire dbit      = (elem == 1 || elem == 3);
    wire last_addr = up ? (addr == MAX) : (addr == 0);
    wire end_of_op = phase ? 1'b1 : !has_write;
    wire [DW-1:0] expected = {DW{exp1}};

    assign addr_o = addr;
    assign we     = (state == RUN) && phase;
    assign wdata  = {DW{dbit}};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; elem <= 0; phase <= 0;
            addr <= 0; fail <= 0; done <= 0;
        end else case (state)
            IDLE: if (start) begin
                state <= RUN; elem <= 0; addr <= 0;
                phase <= 1; fail <= 0; done <= 0;
            end
            RUN: begin
                if (!phase && rdata != expected) fail <= 1;
                if (!end_of_op) phase <= 1;
                else if (last_addr) begin
                    if (elem == 5) begin state <= FIN; done <= 1; end
                    else begin
                        elem  <= elem + 1;
                        addr  <= (elem < 2) ? 0 : MAX;
                        phase <= 0;
                    end
                end else begin
                    addr  <= up ? addr + 1 : addr - 1;
                    phase <= (elem == 0);
                end
            end
            FIN: if (!start) state <= IDLE;
        endcase
    end
endmodule
