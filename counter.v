module counter (
    input        clk,
    input        rst_n,
    input        en,
    output reg [7:0] count
);
    always @(posedge clk) begin
        if (!rst_n)
            count <= 8'd0;
        else if (en)
            count <= count + 8'd1;
    end
endmodule
