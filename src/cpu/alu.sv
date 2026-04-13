`include "types.svh"

//rv32im的实现
module alu (
    input bit clk,
    input bit rst,

    input bit [31:0] pc,

    input Opcode op,
    input bit [4:0] rd,
    input bit [31:0] a,
    input bit [31:0] b,
    input bit [31:0] imm,

    input  bit in_ready,
    output bit out_ready,

    output WritePCReq  write_pc,
    output ReadMemReq  read_mem,
    output WriteMemReq write_mem,
    output WriteRegReq write_reg
);
    enum {
        Idle,
        Run,
        WaitValid,  //等待out_valid为低
        WaitResult
    } state;

    longint a64s;
    longint b64s;
    longint unsigned a64u;
    longint unsigned b64u;
    longint unsigned mul_ss;
    longint unsigned mul_su;
    longint unsigned mul_uu;
    assign a64s   = $signed(a);
    assign b64s   = $signed(b);
    assign a64u   = $unsigned(a);
    assign b64u   = $unsigned(b);
    assign mul_ss = a64s * b64s;
    assign mul_su = a64s * b64u;
    assign mul_uu = a64u * b64u;

    //缓存被除数和除数
    bit [31:0] dividend;
    bit [31:0] divisor;

    bit sdivrem_in_valid;
    bit [63:0] sdivrem_result;
    bit sdivrem_out_valid;
    divrem_signed divrem_signed (
        .aclk(clk),

        .s_axis_dividend_tdata (dividend),
        .s_axis_dividend_tvalid(sdivrem_in_valid),

        .s_axis_divisor_tdata (divisor),
        .s_axis_divisor_tvalid(sdivrem_in_valid),

        .m_axis_dout_tdata (sdivrem_result),
        .m_axis_dout_tvalid(sdivrem_out_valid)
    );

    bit udivrem_in_valid;
    bit [63:0] udivrem_result;
    bit udivrem_out_valid;
    divrem_unsigned divrem_unsigned (
        .aclk(clk),

        .s_axis_dividend_tdata (dividend),
        .s_axis_dividend_tvalid(udivrem_in_valid),

        .s_axis_divisor_tdata (divisor),
        .s_axis_divisor_tvalid(udivrem_in_valid),

        .m_axis_dout_tdata (udivrem_result),
        .m_axis_dout_tvalid(udivrem_out_valid)
    );

    bit meet_cond;

    always_comb begin
        case (op)
            BEq:  meet_cond = a == b;
            BNe:  meet_cond = a != b;
            BLt:  meet_cond = $signed(a) < $signed(b);
            BGe:  meet_cond = $signed(a) >= $signed(b);
            BLtU: meet_cond = $unsigned(a) < $unsigned(b);
            BGeU: meet_cond = $unsigned(a) >= $unsigned(b);
        endcase
    end

    always_ff @(posedge clk) begin
        write_reg.kind <= IntReg;

        case (state)
            Idle: begin
                out_ready <= 0;

                write_pc.enable <= 0;
                read_mem.enable <= 0;
                write_mem.enable <= 0;
                write_reg.enable <= 0;

                if (in_ready) state <= Run;
            end
            Run: begin
                state <= Idle;
                out_ready <= 1;

                write_pc.enable <= 0;
                read_mem.enable <= 0;
                write_mem.enable <= 0;
                write_reg.enable <= 0;

                read_mem.target <= rd;
                write_reg.index <= rd;

                dividend <= a;
                divisor <= b;

                case (op)
                    Lui: begin
                        write_reg.enable <= 1;
                        write_reg.val <= imm;
                    end
                    Auipc: begin
                        write_reg.enable <= 1;
                        write_reg.val <= pc - 4 + imm;
                    end
                    Jal: begin
                        write_reg.enable <= 1;
                        write_reg.val <= pc;

                        write_pc.enable <= 1;
                        write_pc.val <= pc - 4 + imm;
                    end
                    Jalr: begin
                        write_reg.enable <= 1;
                        write_reg.val <= pc;

                        write_pc.enable <= 1;
                        write_pc.val <= a + imm;
                    end
                    BEq, BNe, BLt, BGe, BLtU, BGeU: begin
                        if (meet_cond) begin
                            write_pc.enable <= 1;
                            write_pc.val <= pc - 4 + imm;
                        end
                    end
                    LB, LH, LW, LBU, LHU: begin
                        read_mem.enable <= 1;
                        read_mem.addr   <= a + imm;
                        case (op)
                            LB: begin
                                read_mem.width <= Byte;
                                read_mem.kind  <= IntReg;
                            end
                            LBU: begin
                                read_mem.width <= Byte;
                                read_mem.kind  <= UIntReg;
                            end
                            LH: begin
                                read_mem.width <= HalfWord;
                                read_mem.kind  <= IntReg;
                            end
                            LHU: begin
                                read_mem.width <= HalfWord;
                                read_mem.kind  <= UIntReg;
                            end
                            LW: read_mem.width <= Word;
                        endcase
                    end
                    SB, SH, SW: begin
                        write_mem.enable <= 1;
                        write_mem.addr   <= a + imm;
                        write_mem.data   <= b;
                        case (op)
                            SB: write_mem.width <= Byte;
                            SH: write_mem.width <= HalfWord;
                            SW: write_mem.width <= Word;
                        endcase
                    end
                    AddI: begin
                        write_reg.enable <= 1;
                        write_reg.val <= a + imm;
                    end
                    SltI: begin
                        write_reg.enable <= 1;
                        write_reg.val <= $signed(a) < $signed(imm);
                    end
                    SltU: begin
                        write_reg.enable <= 1;
                        write_reg.val <= $unsigned(a) < $unsigned(imm);
                    end
                    XorI: begin
                        write_reg.enable <= 1;
                        write_reg.val <= a ^ imm;
                    end
                    OrI: begin
                        write_reg.enable <= 1;
                        write_reg.val <= a | imm;
                    end
                    AndI: begin
                        write_reg.enable <= 1;
                        write_reg.val <= a & imm;
                    end
                    SllI: begin
                        write_reg.enable <= 1;
                        write_reg.val <= a << imm;
                    end
                    SrlI: begin
                        write_reg.enable <= 1;
                        write_reg.val <= a >> imm;
                    end
                    SraI: begin
                        write_reg.enable <= 1;
                        write_reg.val <= a >>> imm;
                    end
                    Add: begin
                        write_reg.enable <= 1;
                        write_reg.val <= a + b;
                    end
                    Slt: begin
                        write_reg.enable <= 1;
                        write_reg.val <= $signed(a) < $signed(b);
                    end
                    SltU: begin
                        write_reg.enable <= 1;
                        write_reg.val <= $unsigned(a) < $unsigned(b);
                    end
                    Xor: begin
                        write_reg.enable <= 1;
                        write_reg.val <= a ^ b;
                    end
                    Or: begin
                        write_reg.enable <= 1;
                        write_reg.val <= a | b;
                    end
                    And: begin
                        write_reg.enable <= 1;
                        write_reg.val <= a & b;
                    end
                    Mul: begin
                        write_reg.enable <= 1;
                        write_reg.val <= mul_ss[31:0];
                    end
                    MulH: begin
                        write_reg.enable <= 1;
                        write_reg.val <= mul_ss[63:32];
                    end
                    MulHU: begin
                        write_reg.enable <= 1;
                        write_reg.val <= mul_uu[63:32];
                    end
                    MulHSU: begin
                        write_reg.enable <= 1;
                        write_reg.val <= mul_su[63:32];
                    end
                    Div, DivU, Rem, RemU: begin
                        if (sdivrem_out_valid == 1 || udivrem_out_valid == 1) state <= WaitValid;
                        else begin
                            case (op)
                                Div, Rem:   sdivrem_in_valid <= 1;
                                DivU, RemU: udivrem_in_valid <= 1;
                            endcase
                            state <= WaitResult;
                        end

                        out_ready <= 0;
                    end
                    Fence, FenceI: begin
                        state <= Idle;
                    end
                    default: begin
                        out_ready <= 0;
                        state <= Idle;
                    end
                endcase
            end
            WaitValid: begin
                if (sdivrem_out_valid == 0 && udivrem_out_valid == 0) begin
                    case (op)
                        Div, Rem:   sdivrem_in_valid <= 1;
                        DivU, RemU: udivrem_in_valid <= 1;
                    endcase
                    state <= WaitResult;
                end
            end
            WaitResult: begin
                if (sdivrem_out_valid || udivrem_out_valid) begin
                    case (op)
                        Div: begin
                            write_reg.enable <= 1;
                            write_reg.val <= sdivrem_result[63:32];
                        end
                        DivU: begin
                            write_reg.enable <= 1;
                            write_reg.val <= udivrem_result[63:32];
                        end
                        Rem: begin
                            write_reg.enable <= 1;
                            write_reg.val <= sdivrem_result[31:0];
                        end
                        RemU: begin
                            write_reg.enable <= 1;
                            write_reg.val <= udivrem_result[31:0];
                        end
                    endcase

                    sdivrem_in_valid <= 0;
                    udivrem_in_valid <= 0;
                    out_ready <= 1;

                    state <= Idle;
                end
            end
        endcase
    end

endmodule
