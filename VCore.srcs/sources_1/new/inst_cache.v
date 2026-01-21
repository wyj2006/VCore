`define INST_CACHE_SIZE 128

module inst_cache(input clk,
                  input rst,
                  input[31:0] pc,
                  output[31:0] inst);
    
    reg[7:0] cache[`INST_CACHE_SIZE-1:0];
    
    integer i;
    
    initial begin
        for(i = 0;i<`INST_CACHE_SIZE;i = i+4)begin
            //addi x0,x0,0 (nop)
            {cache[i+3],cache[i+2],cache[i+1],cache[i]} = 32'b000000000000_00000_000_00000_0010011;   //0x00000013
        end
        
        $readmemh("D:/Codes/VCore/tests/test.txt",cache);
    end
    
    assign inst = {cache[pc+3],cache[pc+2],cache[pc+1],cache[pc]};
    
endmodule
