`timescale 1ns / 1ns

module tb_cpu ();
    bit clk = 0;
    bit rst = 1;

    cpu cpu (
        .clk(clk),
        .rst(rst)
    );

    always #0.5 clk = ~clk;

    initial begin
        #0.5;
        rst = 0;
        #0.5;
        rst = 1;
        $readmemh("../../../../src/asm/atomic.txt", cpu.cache.data);
        #200;
        $finish;
    end
endmodule
