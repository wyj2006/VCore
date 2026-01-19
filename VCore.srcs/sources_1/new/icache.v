module icache(input clk,
              input rst,
              input[31:0] addr,
              output[31:0] data);
    
    reg[7:0] memory[1023:0];
    reg[31:0] res_data;
    
    integer i;
    
    assign data = res_data;
    
    always @(negedge rst)  begin
        //addi x0,x0,1
        {memory[3],memory[2],memory[1],memory[0]} = 32'b00000000001_00000_000_00000_0010011;
        
        for(i = 4;i<1024;i = i+4){memory[i+3],memory[i+2],memory[i+1],memory[i+0]} = 0;// 32'b00000000001_00000_000_00000_0010011;
    end
    
    always @(posedge clk) begin
        res_data <= {memory[addr+3],memory[addr+2],memory[addr+1],memory[addr]};
    end
    
endmodule
