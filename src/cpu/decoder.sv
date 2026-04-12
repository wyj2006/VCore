`include "types.svh"

module decoder (
    input bit [31:0] inst,
    output Opcode op,
    output bit [4:0] rd,
    output bit [4:0] rs1,
    output bit [4:0] rs2,
    output bit [31:0] imm,
    output bit [11:0] csr_addr
);

    bit [2:0] funct3;
    bit [6:0] funct7;

    always @(inst) begin
        rd = inst[11:7];
        rs1 = inst[19:15];
        rs2 = inst[24:20];
        funct3 = inst[14:12];
        funct7 = inst[31:25];
        csr_addr = inst[31:20];
        case (inst[6:0])
            'b0000011: begin
                imm = $signed(inst[31:20]);
                case (funct3)
                    'b000: op = LB;
                    'b001: op = LH;
                    'b010: op = LW;
                    'b100: op = LBU;
                    'b101: op = LHU;
                endcase
            end
            'b0000111: begin
                imm = $signed(inst[31:20]);
                case (funct3)
                    'b010: op <= FLW;
                    'b011: op <= FLD;
                endcase
            end
            'b0001111: begin
                //TODO pred succ
                case (funct3)
                    'b000: op <= Fence;
                    'b001: op <= FenceI;
                endcase
            end
            'b0010011: begin
                if (funct3 == 'b001 || funct3 == 'b101) imm = inst[24:20];
                else imm = $signed(inst[31:20]);
                case (funct3)
                    'b000: op = AddI;
                    'b001: op = SllI;
                    'b010: op = SltI;
                    'b011: op = SltIU;
                    'b100: op = XorI;
                    'b101: begin
                        case (funct7)
                            'b0000000: op = SrlI;
                            'b0100000: op = SraI;
                        endcase
                    end
                    'b110: op = OrI;
                    'b111: op = AndI;
                endcase
            end
            'b0010111: begin
                op  = Auipc;
                imm = {inst[31:12], 12'b0};
            end
            'b0100011: begin
                imm = $signed({inst[31:25], inst[11:7]});
                case (funct3)
                    'b000: op = SB;
                    'b001: op = SH;
                    'b010: op = SW;
                endcase
            end
            'b0100111: begin
                imm = $signed({inst[31:25], inst[11:7]});
                case (funct3)
                    'b010: op <= FSW;
                    'b011: op <= FSD;
                endcase
            end
            'b0101111: begin
                //TODO aq rl
                case (funct7[6:2])
                    'b00000: op <= AMOAddW;
                    'b00001: op <= AMOSwapW;
                    'b00010: op <= LRW;
                    'b00011: op <= SCW;
                    'b00100: op <= AMOXorW;
                    'b01000: op <= AMOOrW;
                    'b01100: op <= AMOAndW;
                    'b10000: op <= AMOMinW;
                    'b10100: op <= AMOMaxW;
                    'b11000: op <= AMOMinUW;
                    'b11100: op <= AMOMaxUW;
                endcase
            end
            'b0110011: begin
                case (funct3)
                    'b000: begin
                        case (funct7)
                            'b0000000: op = Add;
                            'b0000001: op = Mul;
                            'b0100000: op = Sub;
                        endcase
                    end
                    'b001: begin
                        case (funct7)
                            'b0000000: op = Sll;
                            'b0000001: op = MulH;
                        endcase
                    end
                    'b010: begin
                        case (funct7)
                            'b0000000: op = Slt;
                            'b0000001: op = MulHSU;
                        endcase
                    end
                    'b011: begin
                        case (funct7)
                            'b0000000: op = SltU;
                            'b0000001: op = MulHU;
                        endcase
                    end
                    'b100: begin
                        case (funct7)
                            'b0000000: op = Xor;
                            'b0000001: op = Div;
                        endcase
                    end
                    'b101: begin
                        case (funct7)
                            'b0000000: op = Srl;
                            'b0000001: op = DivU;
                            'b0100000: op = Sra;
                        endcase
                    end
                    'b110: begin
                        case (funct7)
                            'b0000000: op = Or;
                            'b0000001: op = Rem;
                        endcase
                    end
                    'b111: begin
                        case (funct7)
                            'b0000000: op = And;
                            'b0000001: op = RemU;
                        endcase
                    end
                endcase
            end
            'b0110111: begin
                op  = Lui;
                imm = {inst[31:12], 12'b0};
            end
            'b1010011: begin
                //TODO rm
                case (funct7)
                    'b0000000: op <= FAddS;
                    'b0000001: op <= FAddD;
                    'b0000100: op <= FSubS;
                    'b0000101: op <= FSubD;
                    'b0001000: op <= FMulS;
                    'b0001001: op <= FMulD;
                    'b0001100: begin
                        case (rs2)
                            'b00000: op <= FSqrtS;
                            default: op <= FDivS;
                        endcase
                    end
                    'b0001101: begin
                        case (rs2)
                            'b00000: op <= FSqrtD;
                            default: op <= FDivD;
                        endcase
                    end
                    'b0010000: begin
                        case (funct3)
                            'b000: op <= FSgnJS;
                            'b001: op <= FSgnJNS;
                            'b010: op <= FSgnJXS;
                        endcase
                    end
                    'b0010001: begin
                        case (funct3)
                            'b000: op <= FSgnJD;
                            'b001: op <= FSgnJND;
                            'b010: op <= FSgnJXD;
                        endcase
                    end
                    'b0010100: begin
                        case (funct3)
                            'b000: op <= FMinS;
                            'b001: op <= FMaxS;
                        endcase
                    end
                    'b0010101: begin
                        case (funct3)
                            'b000: op <= FMinD;
                            'b001: op <= FMaxD;
                        endcase
                    end
                    'b1010000: begin
                        case (funct3)
                            'b000: op <= FLeS;
                            'b001: op <= FLtS;
                            'b010: op <= FEqS;
                        endcase
                    end
                    'b1010001: begin
                        case (funct3)
                            'b000: op <= FLeD;
                            'b001: op <= FLtD;
                            'b010: op <= FEqD;
                        endcase
                    end
                    'b1100000: begin
                        case (rs2)
                            'b00000: op <= FCvtWS;
                        endcase
                    end
                    'b1100001: begin
                        case (rs2)
                            'b00000: op <= FCvtWD;
                        endcase
                    end
                    'b1101000: begin
                        case (rs2)
                            'b00000: op <= FCvtSW;
                        endcase
                    end
                    'b1101001: begin
                        case (rs2)
                            'b00000: op <= FMoveDW;
                        endcase
                    end
                    'b1110000: begin
                        case (funct3)
                            'b000: op <= FMoveXW;
                            'b001: op <= FClassS;
                        endcase
                    end
                    'b1110001: begin
                        case (funct3)
                            'b001: op <= FClassD;
                        endcase
                    end
                    'b1111000: op <= FMoveWX;
                endcase
            end
            'b1101111: begin
                op  = Jal;
                imm = $signed({inst[31], inst[19:12], inst[20], inst[30:21], 1'd0});
            end
            'b1100011: begin
                imm = $signed({inst[31], inst[7], inst[30:25], inst[11:8], 1'd0});
                case (funct3)
                    'b000: op = BEq;
                    'b001: op = BNe;
                    'b100: op = BLt;
                    'b101: op = BGe;
                    'b110: op = BLtU;
                    'b111: op = BGeU;
                endcase
            end
            'b1100111: begin
                op  = Jalr;
                imm = $signed(inst[31:20]);
            end
            'b1110011: begin
                imm = $unsigned(inst[19:15]);
                case (funct3)
                    'b000:
                    case (csr_addr)
                        'b000000000000: op <= ECall;
                        'b000000000001: op <= EBreak;
                        'b000100000010: op <= SRet;
                        'b000100000101: op <= WFI;
                        'b001100000010: op <= MRet;
                        default: op <= SFenceVMA;
                    endcase
                    'b001: op <= CSRRW;
                    'b010: op <= CSRRS;
                    'b011: op <= CSRRC;
                    'b101: op <= CSRRWI;
                    'b110: op <= CSRRSI;
                    'b111: op <= CSRRCI;
                endcase
            end
        endcase
    end

endmodule
