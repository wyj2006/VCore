module ifs(input clk,
           input rst,
           input[31:0] pc,
           output[31:0] inst);
    
    icache icache(
    .clk(clk),
    .rst(rst),
    .addr(pc),
    .data(inst)
    );
    
endmodule
