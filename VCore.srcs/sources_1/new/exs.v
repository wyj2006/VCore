`include "inst_def.vh"

module exs(input clk,
           input[31:0] a,
           input[31:0] b,
           input[31:0] imm,
           input[31:0] op,
           input[4:0] rd_to,
           output[4:0] rd_from,
           output rd_we,
           output[31:0] addr,
           output[1:0] rw,
           output[31:0] data);
    
    reg[31:0] res_data;
    reg[31:0] res_rd_we = 0;
    reg[1:0] res_rw     = 0;
    reg[31:0] res_addr  = 0;
    
    assign rd_from = rd_to;
    assign data    = res_data;
    assign rd_we   = res_rd_we;
    assign rw      = res_rw;
    assign addr    = res_addr;
    
    always @(posedge clk) begin
        case (op)
            `ADDI:begin
                res_data  <= a+imm;
                res_rd_we <= 1;
            end
            default:;
        endcase
    end
    
endmodule
