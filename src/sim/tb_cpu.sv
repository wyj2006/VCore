`timescale 1ns / 100ps

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
        $readmemh("../../../../src/asm/matrix.txt", cpu.cache.data);
        #4000;
        $finish;
    end
endmodule
