`include "inst_def.vh"

module ids(input clk,
           input rst,
           input[31:0] inst,
           input we,
           input[4:0] rd_to,
           input[31:0] wdata,
           output[31:0] a,
           output[31:0] b,
           output[31:0] imm,
           output[31:0] op,
           output[4:0] rd_from);
    
    wire[4:0] rs1;
    wire[4:0] rs2;
    wire[6:0] opcode;
    wire[2:0] funct3;
    wire[6:0] funct7;
    
    reg[31:0] res_imm;
    reg[31:0] res_op;
    
    regfile regfile(
    .clk(clk),
    .rst(rst),
    .raddr1(rs1),
    .rdata1(a),
    .raddr2(rs2),
    .rdata2(b),
    .we(we),
    .waddr(rd_to),
    .wdata(wdata)
    );
    
    assign rs1     = inst[19:5];
    assign rs2     = inst[24:20];
    assign rd_from = inst[11:7];
    assign opcode  = inst[6:0];
    assign funct3  = inst[14:12];
    assign funct7  = inst[31:25];
    assign op      = res_op;
    assign imm     = res_imm;
    
    always @(posedge clk) begin
        case (opcode)
            'b0010011:begin //I-type
                res_imm <= inst[31:20];
                case (funct3)
                    'b000:begin
                        res_op <= `ADDI;
                    end
                    default:;
                endcase
            end
            default:;
        endcase
    end
    
endmodule
