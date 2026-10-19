module counter_tb;
    reg clk = 0, rst_n = 0, en = 0;
    wire [7:0] count;
    counter dut (.clk(clk), .rst_n(rst_n), .en(en), .count(count));
    always #5 clk = ~clk;
    initial begin
        #12 rst_n = 1; en = 1;
        #100 $display("count = %d", count);
        $finish;
    end
endmodule
