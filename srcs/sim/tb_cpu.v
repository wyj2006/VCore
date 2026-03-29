`timescale 1ns/1ns

module tb_cpu();
    
    reg clk = 0;
    reg rst = 1;
    
    cpu cpu(
    .clk(clk),
    .rst(rst)
    );
    
    always #1 clk = ~clk;
    
    initial begin
        #1;
        rst = 0;
        #1;
        rst = 1;
        #100;
        $finish;
    end
    
endmodule
