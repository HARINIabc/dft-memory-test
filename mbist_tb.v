module mbist_tb;
    reg clk = 0, rst_n = 0, start = 0;
    always #5 clk = ~clk;

    wire [3:0] a0, a1;
    wire we0, we1, done0, fail0, done1, fail1;
    wire [7:0] wd0, wd1, rd0, rd1;

    mbist m0 (.clk(clk), .rst_n(rst_n), .start(start), .done(done0), .fail(fail0),
              .addr_o(a0), .we(we0), .wdata(wd0), .rdata(rd0));
    sram #(.FAULT_EN(0)) s0 (.clk(clk), .we(we0), .addr(a0), .din(wd0), .dout(rd0));

    mbist m1 (.clk(clk), .rst_n(rst_n), .start(start), .done(done1), .fail(fail1),
              .addr_o(a1), .we(we1), .wdata(wd1), .rdata(rd1));
    sram #(.FAULT_EN(1)) s1 (.clk(clk), .we(we1), .addr(a1), .din(wd1), .dout(rd1));

    initial begin
        #22 rst_n = 1;
        #10 start = 1;
        wait (done0 && done1);
        #10;
        $display("Good memory:   done=%b fail=%b (expect fail=0)", done0, fail0);
        $display("Faulty memory: done=%b fail=%b (expect fail=1)", done1, fail1);
        $finish;
    end
    initial begin #20000 $display("TIMEOUT"); $finish; end
endmodule

