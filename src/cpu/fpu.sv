`include "types.svh"

//rv32fd的实现
module fpu (
    input bit clk,
    input bit rst,

    input Opcode op,
    input bit [4:0] rd,
    input bit [63:0] fa,
    input bit [63:0] fb,
    input bit [31:0] imm,
    input bit [31:0] ia,

    input  bit in_ready,
    output bit out_ready,

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

    typedef enum bit [3:0] {
        FAdder = 0,
        DAdder,
        FMuler,
        DMuler,
        FDiver,
        DDiver,
        FSqrter,
        DSqrter,
        FComparer,
        DComparer,
        FToInt32,
        Int32ToF,
        DoubleToFloat,
        FloatToDouble,
        DoubleToInt32
    } Index;
    bit in_valid[15];
    bit out_valid[15];

    //某一个out_valid[i]为1
    bit has_out_valid;

    always_comb begin
        for (int i = 0; i < 15; i = i + 1) begin
            if (i == 0) has_out_valid = out_valid[i];
            else has_out_valid = has_out_valid | out_valid[i];
        end
    end

    bit [63:0] a, b;  //对fa, fb的缓存
    bit [31:0] c;  //对ia的缓存

    bit [ 7:0] fp_adder_op;

    bit [31:0] fadder_result;
    fadder fadder (
        .aclk(clk),

        .s_axis_a_tdata (a[31:0]),
        .s_axis_a_tvalid(in_valid[FAdder]),

        .s_axis_b_tdata (b[31:0]),
        .s_axis_b_tvalid(in_valid[FAdder]),

        .s_axis_operation_tdata (fp_adder_op),
        .s_axis_operation_tvalid(in_valid[FAdder]),

        .m_axis_result_tdata (fadder_result),
        .m_axis_result_tvalid(out_valid[FAdder])
    );

    bit [63:0] dadder_result;
    dadder dadder (
        .aclk(clk),

        .s_axis_a_tdata (a),
        .s_axis_a_tvalid(in_valid[DAdder]),

        .s_axis_b_tdata (b),
        .s_axis_b_tvalid(in_valid[DAdder]),

        .s_axis_operation_tdata (fp_adder_op),
        .s_axis_operation_tvalid(in_valid[DAdder]),

        .m_axis_result_tdata (dadder_result),
        .m_axis_result_tvalid(out_valid[DAdder])
    );

    bit [31:0] fmuler_result;
    fmuler fmuler (
        .aclk(clk),

        .s_axis_a_tdata (a[31:0]),
        .s_axis_a_tvalid(in_valid[FMuler]),

        .s_axis_b_tdata (b[31:0]),
        .s_axis_b_tvalid(in_valid[FMuler]),

        .m_axis_result_tdata (fmuler_result),
        .m_axis_result_tvalid(out_valid[FMuler])
    );

    bit [63:0] dmuler_result;
    dmuler dmuler (
        .aclk(clk),

        .s_axis_a_tdata (a),
        .s_axis_a_tvalid(in_valid[DMuler]),

        .s_axis_b_tdata (b),
        .s_axis_b_tvalid(in_valid[DMuler]),

        .m_axis_result_tdata (dmuler_result),
        .m_axis_result_tvalid(out_valid[DMuler])
    );

    bit [31:0] fdiver_result;
    fdiver fdiver (
        .aclk(clk),

        .s_axis_a_tdata (a[31:0]),
        .s_axis_a_tvalid(in_valid[FDiver]),

        .s_axis_b_tdata (b[31:0]),
        .s_axis_b_tvalid(in_valid[FDiver]),

        .m_axis_result_tdata (fdiver_result),
        .m_axis_result_tvalid(out_valid[FDiver])
    );

    bit [63:0] ddiver_result;
    ddiver ddiver (
        .aclk(clk),

        .s_axis_a_tdata (a),
        .s_axis_a_tvalid(in_valid[DDiver]),

        .s_axis_b_tdata (b),
        .s_axis_b_tvalid(in_valid[DDiver]),

        .m_axis_result_tdata (ddiver_result),
        .m_axis_result_tvalid(out_valid[DDiver])
    );

    bit [31:0] fsqrter_result;
    fsqrter fsqrter (
        .aclk(clk),

        .s_axis_a_tdata (a[31:0]),
        .s_axis_a_tvalid(in_valid[FSqrter]),

        .m_axis_result_tdata (fsqrter_result),
        .m_axis_result_tvalid(out_valid[FSqrter])
    );

    bit [63:0] dsqrter_result;
    dsqrter dsqrter (
        .aclk(clk),

        .s_axis_a_tdata (a),
        .s_axis_a_tvalid(in_valid[DSqrter]),

        .m_axis_result_tdata (dsqrter_result),
        .m_axis_result_tvalid(out_valid[DSqrter])
    );

    bit [ 7:0] fp_comparer_op;

    bit [31:0] fcomparer_result;
    fcomparer fcomparer (
        .aclk(clk),

        .s_axis_a_tdata (a[31:0]),
        .s_axis_a_tvalid(in_valid[FComparer]),

        .s_axis_b_tdata (b[31:0]),
        .s_axis_b_tvalid(in_valid[FComparer]),

        .s_axis_operation_tdata (fp_comparer_op),
        .s_axis_operation_tvalid(in_valid[FComparer]),

        .m_axis_result_tdata (fcomparer_result),
        .m_axis_result_tvalid(out_valid[FComparer])
    );

    bit [63:0] dcomparer_result;
    dcomparer dcomparer (
        .aclk(clk),

        .s_axis_a_tdata (a),
        .s_axis_a_tvalid(in_valid[DComparer]),

        .s_axis_b_tdata (b),
        .s_axis_b_tvalid(in_valid[DComparer]),

        .s_axis_operation_tdata (fp_comparer_op),
        .s_axis_operation_tvalid(1),

        .m_axis_result_tdata (dcomparer_result),
        .m_axis_result_tvalid(out_valid[DComparer])
    );

    bit [31:0] ftoint32_result;
    ftoint32 ftoint32 (
        .aclk(clk),

        .s_axis_a_tdata (a[31:0]),
        .s_axis_a_tvalid(in_valid[FToInt32]),

        .m_axis_result_tdata (ftoint32_result),
        .m_axis_result_tvalid(out_valid[FToInt32])
    );

    bit [31:0] int32tof_result;
    int32tof int32tof (
        .aclk(clk),

        .s_axis_a_tdata (c),
        .s_axis_a_tvalid(in_valid[Int32ToF]),

        .m_axis_result_tdata (int32tof_result),
        .m_axis_result_tvalid(out_valid[Int32ToF])
    );

    bit [31:0] dtof_result;
    double_to_float double_to_float (
        .aclk(clk),

        .s_axis_a_tdata (a),
        .s_axis_a_tvalid(in_valid[DoubleToFloat]),

        .m_axis_result_tdata (dtof_result),
        .m_axis_result_tvalid(out_valid[DoubleToFloat])
    );

    bit [63:0] ftod_result;
    float_to_double float_to_double (
        .aclk(clk),

        .s_axis_a_tdata (a[31:0]),
        .s_axis_a_tvalid(in_valid[FloatToDouble]),

        .m_axis_result_tdata (ftod_result),
        .m_axis_result_tvalid(out_valid[FloatToDouble])
    );

    bit [31:0] dtoint32_result;
    dtoint32 dtoint32 (
        .aclk(clk),

        .s_axis_a_tdata (a),
        .s_axis_a_tvalid(in_valid[DoubleToInt32]),

        .m_axis_result_tdata (dtoint32_result),
        .m_axis_result_tvalid(out_valid[DoubleToInt32])
    );

    always_ff @(posedge clk) begin
        case (state)
            Idle: begin
                out_ready <= 0;

                read_mem.enable <= 0;
                write_mem.enable <= 0;
                write_reg.enable <= 0;

                if (in_ready) state <= Run;
            end
            Run: begin
                state <= Idle;
                out_ready <= 1;

                read_mem.enable <= 0;
                write_mem.enable <= 0;
                write_reg.enable <= 0;

                read_mem.target <= rd;
                write_reg.index <= rd;

                a <= fa;
                b <= fb;
                c <= ia;

                case (op)
                    FLW: begin
                        read_mem.enable <= 1;
                        read_mem.addr   <= ia + imm;
                        read_mem.width  <= Word;
                        read_mem.kind   <= FloatReg;
                    end
                    FLD: begin
                        read_mem.enable <= 1;
                        read_mem.addr   <= ia + imm;
                        read_mem.width  <= DoubleWord;
                        read_mem.kind   <= DoubleReg;
                    end
                    FSW: begin
                        write_mem.enable <= 1;
                        write_mem.addr   <= ia + imm;
                        write_mem.data   <= fb[31:0];
                        write_mem.width  <= Word;
                    end
                    FSD: begin
                        write_mem.enable <= 1;
                        write_mem.addr   <= ia + imm;
                        write_mem.data   <= fb;
                        write_mem.width  <= DoubleWord;
                    end
                    FSgnJS: begin
                        write_reg.enable <= 1;
                        write_reg.kind <= FloatReg;
                        write_reg.val <= {fb[31], fa[30:0]};
                    end
                    FSgnJD: begin
                        write_reg.enable <= 1;
                        write_reg.kind <= DoubleReg;
                        write_reg.val <= {fb[63], fa[62:0]};
                    end
                    FSgnJNS: begin
                        write_reg.enable <= 1;
                        write_reg.kind <= FloatReg;
                        write_reg.val <= {1 - fb[31], fa[30:0]};
                    end
                    FSgnJND: begin
                        write_reg.enable <= 1;
                        write_reg.kind <= DoubleReg;
                        write_reg.val <= {1 - fb[63], fa[62:0]};
                    end
                    FSgnJXS: begin
                        write_reg.enable <= 1;
                        write_reg.kind <= FloatReg;
                        write_reg.val <= {fa[31] ^ fb[31], fa[30:0]};
                    end
                    FSgnJXD: begin
                        write_reg.enable <= 1;
                        write_reg.kind <= DoubleReg;
                        write_reg.val <= {fa[63] ^ fb[63], fa[62:0]};
                    end
                    FMoveXW: begin
                        write_reg.enable <= 1;
                        write_reg.kind <= IntReg;
                        write_reg.val <= fa[31:0];
                    end
                    FMoveWX: begin
                        write_reg.enable <= 1;
                        write_reg.kind <= FloatReg;
                        write_reg.val <= ia;
                    end
                    FMoveDW: begin
                        write_reg.enable <= 1;
                        write_reg.kind <= DoubleReg;
                        write_reg.val <= fa[31:0];
                    end
                    FAddS, FAddD: begin
                        fp_adder_op <= 0;
                        out_ready <= 0;
                        state <= WaitValid;
                    end
                    FSubS, FSubD: begin
                        fp_adder_op <= 1;
                        out_ready <= 0;
                        state <= WaitValid;
                    end
                    FMinS, FMaxS, FMinD, FMaxD: begin
                        fp_comparer_op <= 'b001100;
                        out_ready <= 0;
                        state <= WaitValid;
                    end
                    FEqS, FEqD: begin
                        fp_comparer_op <= 'b010100;
                        out_ready <= 0;
                        state <= WaitValid;
                    end
                    FLtS, FLtD: begin
                        fp_comparer_op <= 'b001100;
                        out_ready <= 0;
                        state <= WaitValid;
                    end
                    FLeS, FLeD: begin
                        fp_comparer_op <= 'b011100;
                        out_ready <= 0;
                        state <= WaitValid;
                    end
                    FMulS, FMulD, FDivS, FDivD, FSqrtS, FSqrtD, FCvtWS, FCvtSW, FCvtSD, FCvtDS, FCvtWD: begin
                        out_ready <= 0;
                        state <= WaitValid;
                    end
                    default: begin
                        out_ready <= 0;
                        state <= Idle;
                    end
                endcase
            end
            WaitValid: begin
                if (has_out_valid == 0) begin
                    state <= WaitResult;
                    case (op)
                        FAddS, FSubS: in_valid[FAdder] <= 1;
                        FAddD, FSubD: in_valid[DAdder] <= 1;
                        FMulS: in_valid[FMuler] <= 1;
                        FMulD: in_valid[DMuler] <= 1;
                        FDivS: in_valid[FDiver] <= 1;
                        FDivD: in_valid[DDiver] <= 1;
                        FSqrtS: in_valid[FSqrter] <= 1;
                        FSqrtD: in_valid[DSqrter] <= 1;
                        FMinS, FMaxS, FEqS, FLtS, FLeS: in_valid[FComparer] <= 1;
                        FMinD, FMaxD, FEqD, FLtD, FLeD: in_valid[DComparer] <= 1;
                        FCvtWS: in_valid[FToInt32] <= 1;
                        FCvtSW: in_valid[Int32ToF] <= 1;
                        FCvtSD: in_valid[DoubleToFloat] <= 1;
                        FCvtDS: in_valid[FloatToDouble] <= 1;
                        FCvtWD: in_valid[DoubleToInt32] <= 1;
                    endcase
                end
            end
            WaitResult: begin
                //out_valid中最多只有一个1
                if (has_out_valid == 1) begin
                    state <= Idle;
                    out_ready <= 1;
                    in_valid = '{default: 0};
                    write_reg.enable <= 1;
                    case (op)
                        FAddS, FSubS: begin
                            write_reg.kind <= FloatReg;
                            write_reg.val  <= fadder_result;
                        end
                        FAddD, FSubD: begin
                            write_reg.kind <= DoubleReg;
                            write_reg.val  <= dadder_result;
                        end
                        FMulS: begin
                            write_reg.kind <= FloatReg;
                            write_reg.val  <= fmuler_result;
                        end
                        FMulD: begin
                            write_reg.kind <= DoubleReg;
                            write_reg.val  <= dmuler_result;
                        end
                        FDivS: begin
                            write_reg.kind <= FloatReg;
                            write_reg.val  <= fdiver_result;
                        end
                        FDivD: begin
                            write_reg.kind <= DoubleReg;
                            write_reg.val  <= ddiver_result;
                        end
                        FSqrtS: begin
                            write_reg.kind <= FloatReg;
                            write_reg.val  <= fsqrter_result;
                        end
                        FSqrtD: begin
                            write_reg.kind <= DoubleReg;
                            write_reg.val  <= dsqrter_result;
                        end
                        FMinS: begin
                            write_reg.kind <= FloatReg;
                            write_reg.val  <= fcomparer_result[0] == 1 ? fa[31:0] : fb[31:0];
                        end
                        FMaxS: begin
                            write_reg.kind <= FloatReg;
                            write_reg.val  <= fcomparer_result[0] == 1 ? fb[31:0] : fa[31:0];
                        end
                        FMinD: begin
                            write_reg.kind <= FloatReg;
                            write_reg.val  <= fcomparer_result[0] == 1 ? fa : fb;
                        end
                        FMaxD: begin
                            write_reg.kind <= DoubleReg;
                            write_reg.val  <= fcomparer_result[0] == 1 ? fb : fa;
                        end
                        FEqS, FLtS, FLeS: begin
                            write_reg.kind <= IntReg;
                            write_reg.val  <= fcomparer_result[0];
                        end
                        FEqD, FLtD, FLeD: begin
                            write_reg.kind <= IntReg;
                            write_reg.val  <= dcomparer_result[0];
                        end
                        FCvtWS: begin
                            write_reg.kind <= IntReg;
                            write_reg.val  <= ftoint32_result;
                        end
                        FCvtSW: begin
                            write_reg.kind <= FloatReg;
                            write_reg.val  <= int32tof_result;
                        end
                        FCvtSD: begin
                            write_reg.kind <= FloatReg;
                            write_reg.val  <= dtof_result;
                        end
                        FCvtDS: begin
                            write_reg.kind <= DoubleReg;
                            write_reg.val  <= ftod_result;
                        end
                        FCvtWD: begin
                            write_reg.kind <= IntReg;
                            write_reg.val  <= dtoint32_result;
                        end
                    endcase
                end
            end
        endcase
    end

endmodule
