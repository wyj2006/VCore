`timescale 1ns/1ns

module tb_cpu();
    
    reg clk = 0;
    reg rst = 1;
    
    cpu cpu(
    .clk(clk),
    .rst(rst)
    );
    
    always #10 clk = ~clk;
    
    initial begin
        #10;
        rst = 0;
        #10;
        rst = 1;
        #1000
        $stop;
    end
    
endmodule
