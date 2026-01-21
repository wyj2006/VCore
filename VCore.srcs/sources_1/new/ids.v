`include "inst_def.vh"

module ids(input clk,
           input[5:0] flush,
           input[5:0] stall,
           input[31:0] inst,
           output reg[4:0] rs1,
           output reg[4:0] rs2,
           output reg[31:0] imm,
           output reg[7:0] op,
           output reg[4:0] rd);
    
    wire[6:0] opcode;
    wire[2:0] funct3;
    wire[6:0] funct7;
    
    assign opcode = inst[6:0];
    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];
    
    always @(posedge clk) begin
        case(1)
            flush[1]:begin
                imm <= 0;
                rs1 <= 0;
                rs2 <= 0;
                rd  <= 0;
                op  <= `ADDI;
            end
            stall[1]:;
            default:begin
                imm <= 0;
                rs1 <= inst[19:15];
                rs2 <= inst[24:20];
                rd  <= inst[11:7];
                op  <= 0;
                case (opcode)
                    'b0110111:begin
                        op  <= `LUI;
                        imm <= {inst[31:12],12'd0};
                    end
                    'b0010111:begin
                        op  <= `AUIPC;
                        imm <= {inst[31:12],12'd0};
                    end
                    'b1101111:begin
                        op  <= `JAL;
                        imm <= $signed({inst[31],inst[19:12],inst[20],inst[30:21],1'd0});
                    end
                    'b1100111:begin
                        op  <= `JALR;
                        imm <= $signed(inst[31:20]);
                    end
                    'b1100011:begin // B-type
                        imm <= $signed({inst[31],inst[7],inst[30:25],inst[11:8],1'd0});
                        case(funct3)
                            'b000: op <= `BEQ;
                            'b001: op <= `BNE;
                            'b100: op <= `BLT;
                            'b101: op <= `BGE;
                            'b110: op <= `BLTU;
                            'b111: op <= `BGEU;
                            default:;
                        endcase
                    end
                    'b0000011:begin // I-type (load)
                        imm <= $signed(inst[31:20]);
                        case (funct3)
                            'b000: op <= `LB;
                            'b001: op <= `LH;
                            'b010: op <= `LW;
                            'b100: op <= `LBU;
                            'b101: op <= `LHU;
                            default:;
                        endcase
                    end
                    'b0100011:begin // S-type
                        imm <= $signed({inst[31:25],inst[11:7]});
                        case (funct3)
                            'b000: op <= `SB;
                            'b001: op <= `SH;
                            'b010: op <= `SW;
                            default:;
                        endcase
                    end
                    'b0010011:begin // I-type
                        imm <= $signed(inst[31:20]);
                        case (funct3)
                            'b000: op <= `ADDI;
                            'b010: op <= `SLTI;
                            'b011: op <= `SLTIU;
                            'b100: op <= `XORI;
                            'b110: op <= `ORI;
                            'b111: op <= `ANDI;
                            default:begin
                                imm <= inst[24:20];
                                case(funct3)
                                    'b001: op <= `SLLI;
                                    'b101: begin
                                        case(funct7)
                                            'b0000000:op <= `SRLI;
                                            'b0100000:op <= `SRAI;
                                            default:;
                                        endcase
                                    end
                                    default:;
                                endcase
                            end
                        endcase
                    end
                    'b0110011:begin // R-type
                        case(funct3)
                            'b000:begin
                                case(funct7)
                                    'b0000000:op <= `ADD;
                                    'b0100000:op <= `SUB;
                                    default:;
                                endcase
                            end
                            'b001:op <= `SLL;
                            'b010:op <= `SLT;
                            'b011:op <= `SLTU;
                            'b100:op <= `XOR;
                            'b101:begin
                                case(funct7)
                                    'b0000000:op <= `SRL;
                                    'b0100000:op <= `SRA;
                                    default:;
                                endcase
                            end
                            'b110:op <= `OR;
                            'b111:op <= `AND;
                            default:;
                        endcase
                    end
                    default:;
                endcase
            end
        endcase
    end
    
endmodule
