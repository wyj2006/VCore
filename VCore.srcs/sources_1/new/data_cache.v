module data_cache(input clk,
                  input[31:0] addr,
                  input we,
                  input [31:0] wdata,
                  output[31:0] rdata);
    
    reg[7:0] memory[1023:0];
    
    always @(posedge clk) begin
        if (we){memory[addr+3],memory[addr+2],memory[addr+1],memory[addr]} <= wdata;
    end
    
    assign rdata = {memory[addr+3],memory[addr+2],memory[addr+1],memory[addr]};
    
endmodule
