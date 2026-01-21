`include "inst_def.vh"

module exs(input clk,
           input[5:0] flush,
           input[5:0] stall,
           input[31:0] pc,
           input[31:0] a,
           input[31:0] b,
           input[31:0] imm,
           input[7:0] op,
           input[4:0] rd_to,
           output reg[4:0] rd_from,
           output reg rd_we,
           output reg[5:0] ulrw,
           output reg[31:0] result,
           output reg[31:0] addr,
           output reg pc_we,
           output reg[31:0] pc_new);
    
    always @(posedge clk) begin
        case(1)
            flush[3]||stall[3]&&!stall[4]:begin
                ulrw    <= 0;
                rd_we   <= 0;
                pc_we   <= 0;
                rd_from <= 0;
            end
            stall[3]:;
            default:begin
                ulrw    <= 0;
                rd_we   <= 0;
                pc_we   <= 0;
                rd_from <= rd_to;
                case (op)
                    `LUI:begin
                        result <= imm;
                        rd_we  <= 1;
                    end
                    `AUIPC:begin
                        result <= pc-8+imm;
                        rd_we  <= 1;
                    end
                    `JAL:begin
                        result <= pc-8+4;
                        pc_new <= pc-8+imm;
                        pc_we  <= 1;
                        rd_we  <= 1;
                    end
                    `JALR:begin
                        result <= pc-8+4;
                        pc_new <= a+imm;
                        pc_we  <= 1;
                        rd_we  <= 1;
                    end
                    `BEQ:begin
                        if (a == b)begin
                            pc_new <= pc-8+imm;
                            pc_we  <= 1;
                        end
                    end
                    `BNE:begin
                        if (!(a == b))begin
                            pc_new <= pc-8+imm;
                            pc_we  <= 1;
                        end
                    end
                    `BLT:begin
                        if ($signed(a) < $signed(b))begin
                            pc_new <= pc-8+imm;
                            pc_we  <= 1;
                        end
                    end
                    `BGE:begin
                        if (!($signed(a) < $signed(b)))begin
                            pc_new <= pc-8+imm;
                            pc_we  <= 1;
                        end
                    end
                    `BLTU:begin
                        if (a < b)begin
                            pc_new <= pc-8+imm;
                            pc_we  <= 1;
                        end
                    end
                    `BGEU:begin
                        if (!(a < b))begin
                            pc_new <= pc-8+imm;
                            pc_we  <= 1;
                        end
                    end
                    `LB:begin
                        addr  <= a+imm;
                        rd_we <= 1;
                        ulrw  <= 'b0_001_10;
                    end
                    `LH:begin
                        addr  <= a+imm;
                        rd_we <= 1;
                        ulrw  <= 'b0_010_10;
                    end
                    `LW:begin
                        addr  <= a+imm;
                        rd_we <= 1;
                        ulrw  <= 'b0_100_10;
                    end
                    `LBU:begin
                        addr  <= a+imm;
                        rd_we <= 1;
                        ulrw  <= 'b1_001_10;
                    end
                    `LHU:begin
                        addr  <= a+imm;
                        rd_we <= 1;
                        ulrw  <= 'b1_010_10;
                    end
                    `SB:begin
                        addr   <= a+imm;
                        result <= b;
                        ulrw   <= 'b0_001_01;
                    end
                    `SH:begin
                        addr   <= a+imm;
                        result <= b;
                        ulrw   <= 'b0_010_01;
                    end
                    `SW:begin
                        addr   <= a+imm;
                        result <= b;
                        ulrw   <= 'b0_100_01;
                    end
                    `ADDI:begin
                        result <= a+imm;
                        rd_we  <= 1;
                    end
                    `SLTI:begin
                        result <= $signed(a)<$signed(imm);
                        rd_we  <= 1;
                    end
                    `SLTIU:begin
                        result <= a<imm;
                        rd_we  <= 1;
                    end
                    `XORI:begin
                        result <= a^imm;
                        rd_we  <= 1;
                    end
                    `ORI:begin
                        result <= a|imm;
                        rd_we  <= 1;
                    end
                    `ANDI:begin
                        result <= a&imm;
                        rd_we  <= 1;
                    end
                    `SLLI:begin
                        result <= a<<imm;
                        rd_we  <= 1;
                    end
                    `SRLI:begin
                        result <= a>>imm;
                        rd_we  <= 1;
                    end
                    `SRAI:begin
                        result <= a>>>imm;
                        rd_we  <= 1;
                    end
                    `ADD:begin
                        result <= a+b;
                        rd_we  <= 1;
                    end
                    `SLT:begin
                        result <= $signed(a)<$signed(b);
                        rd_we  <= 1;
                    end
                    `SLTU:begin
                        result <= a<b;
                        rd_we  <= 1;
                    end
                    `XOR:begin
                        result <= a^b;
                        rd_we  <= 1;
                    end
                    `OR:begin
                        result <= a|b;
                        rd_we  <= 1;
                    end
                    `AND:begin
                        result <= a&b;
                        rd_we  <= 1;
                    end
                    default:;
                endcase
            end
        endcase
    end
    
endmodule
