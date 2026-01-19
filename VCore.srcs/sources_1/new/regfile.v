module regfile(input clk,
               input rst,
               input[4:0] raddr1,
               output[31:0] rdata1,
               input[4:0] raddr2,
               output[31:0] rdata2,
               input we,
               input[4:0] waddr,
               input[31:0] wdata);
    
    reg[31:0] regs[31:0];
    
    integer i;
    
    always @(posedge clk) begin
        if (we)regs[waddr] <= wdata;
    end
    
    always @(negedge rst) begin
        for(i = 0;i<32;i = i+1)regs[i] = 0;
    end
    
    assign rdata1 = regs[raddr1];
    assign rdata2 = regs[raddr2];
    
endmodule
