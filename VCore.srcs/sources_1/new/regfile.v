module regfile(input clk,
               input rst,
               input[4:0] raddr1,
               output [31:0] rdata1,
               input[4:0] raddr2,
               output [31:0] rdata2,
               input we,
               input[4:0] waddr,
               input[31:0] wdata);
    
    reg[31:0] x[31:0];
    
    integer i;
    
    always @(negedge rst) begin
        for(i = 0;i<32;i = i+1)begin
            case(i)
                2:x[i]       <= 32;//sp
                default:x[i] <= 0;
            endcase
        end
    end
    
    always @(posedge clk) begin
        if (we) x[waddr] <= wdata;
    end
    
    assign rdata1 = x[raddr1];
    assign rdata2 = x[raddr2];
    
endmodule
