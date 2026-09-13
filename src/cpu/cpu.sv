`include "types.svh"

module cpu (
    input bit clk,
    input bit rst
);
    typedef enum bit [2:0] {
        Fetch,
        Decode,
        Execute,
        ReadMem,
        WriteMem,
        DetectTrap
    } State;
    State state;
    State pre_state;

    bit [31:0] pc;
    ReadMemReq pc_read_mem;
    assign pc_read_mem.width = Word;

    ReadMemReq read_mem;
    WriteMemReq write_mem;
    WriteRegReq write_reg_back;

    bit [63:0] cache_out;
    bit read_done;
    bit write_done;
    cache cache (
        .clk(clk),
        .rst(rst),

        .read_addr  (read_mem.addr),
        .read_enable(read_mem.enable),
        .read_width (read_mem.width),
        .read_data  (cache_out),
        .read_done  (read_done),

        .write_addr  (write_mem.addr),
        .write_data  (write_mem.data),
        .write_width (write_mem.width),
        .write_enable(write_mem.enable),
        .write_done  (write_done)
    );

    bit [31:0] cache_out_u8;
    bit [31:0] cache_out_i8;
    bit [31:0] cache_out_u16;
    bit [31:0] cache_out_i16;
    bit [31:0] cache_out_u32;
    bit [31:0] cache_out_i32;
    assign cache_out_u8  = $unsigned(cache_out[7:0]);
    assign cache_out_i8  = $signed(cache_out[7:0]);
    assign cache_out_u16 = $unsigned(cache_out[15:0]);
    assign cache_out_i16 = $signed(cache_out[15:0]);
    assign cache_out_u32 = $unsigned(cache_out[31:0]);
    assign cache_out_i32 = $signed(cache_out[31:0]);

    bit [31:0] inst;
    Opcode op;
    bit [4:0] rd;
    bit [4:0] rs1;
    bit [4:0] rs2;
    bit [31:0] imm;
    bit [11:0] csr_addr;
    decoder decoder (
        .inst(inst),
        .op(op),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .imm(imm),
        .csr_addr(csr_addr)
    );

    bit execute_alu;
    bit execute_fpu;
    bit execute_atomic;
    bit execute_csr_unit;
    bit execute_trap_ctrl;
    bit need_read_mem;
    bit need_read_inst;

    assign execute_alu = op inside {[Lui : RemU]};
    assign execute_fpu = op inside {[FLW : FMoveDW]};
    assign execute_atomic = op inside {[LRW : AMOMaxUW]};
    assign execute_csr_unit = op inside {[CSRRW : CSRRCI]};
    assign execute_trap_ctrl = op inside {MRet, ECall, EBreak, Illegal};
    assign need_read_mem = op inside {LB, LH, LW, LBU, LHU, FLW, FSW, FLD, FSD, LRW};
    assign need_read_inst = state == Fetch || (state == ReadMem && pre_state == Fetch);

    WriteRegReq write_reg;
    bit [63:0] reg_value[4];
    regfile regfile (
        .clk(clk),
        .rst(rst),
        .index({rs1, rs2, rs1, rs2}),
        .kind({IntReg, IntReg, DoubleReg, DoubleReg}),
        .value(reg_value),
        .write_reg(write_reg)
    );

    bit alu_in_ready;
    bit alu_out_ready;
    WritePCReq alu_write_pc;
    ReadMemReq alu_read_mem;
    WriteMemReq alu_write_mem;
    WriteRegReq alu_write_reg;
    alu alu (
        .clk(clk),
        .rst(rst),

        .pc(pc),

        .op (op),
        .rd (rd),
        .a  (reg_value[0][31:0]),
        .b  (reg_value[1][31:0]),
        .imm(imm),

        .in_ready (alu_in_ready),
        .out_ready(alu_out_ready),

        .write_pc (alu_write_pc),
        .read_mem (alu_read_mem),
        .write_mem(alu_write_mem),
        .write_reg(alu_write_reg)
    );

    bit fpu_in_ready;
    bit fpu_out_ready;
    WritePCReq fpu_write_pc;
    ReadMemReq fpu_read_mem;
    WriteMemReq fpu_write_mem;
    WriteRegReq fpu_write_reg;
    fpu fpu (
        .clk(clk),
        .rst(rst),

        .op (op),
        .rd (rd),
        .fa (reg_value[2]),
        .fb (reg_value[3]),
        .imm(imm),
        .ia (reg_value[0][31:0]),

        .in_ready (fpu_in_ready),
        .out_ready(fpu_out_ready),

        .read_mem (fpu_read_mem),
        .write_mem(fpu_write_mem),
        .write_reg(fpu_write_reg)
    );

    bit atom_in_ready;
    bit atom_out_ready;
    ReadMemReq atom_read_mem;
    WriteMemReq atom_write_mem;
    WriteRegReq atom_write_reg;
    atomic atomic (
        .clk(clk),
        .rst(rst),

        .op(op),
        .rd(rd),
        .a (reg_value[0][31:0]),
        .b (reg_value[1][31:0]),

        .in_ready (atom_in_ready),
        .out_ready(atom_out_ready),

        .cache_out(cache_out),

        .read_mem (atom_read_mem),
        .write_mem(atom_write_mem),
        .write_reg(atom_write_reg)
    );

    bit csr_unit_in_ready;
    bit csr_unit_out_ready;
    WriteCSRReq write_csr[3];
    WriteRegReq csr_unit_write_reg;
    TrapRelatedCSRs trap_csrs;
    csr_unit csr_unit (
        .clk(clk),
        .rst(rst),

        .op(op),
        .csr_addr(csr_addr),
        .rd(rd),
        .rs1(rs1),
        .a(reg_value[0][31:0]),
        .imm(imm),

        .in_ready (csr_unit_in_ready),
        .out_ready(csr_unit_out_ready),

        .ext_write_csr(write_csr),

        .trap_csrs(trap_csrs),
        .write_reg(csr_unit_write_reg)
    );

    bit trap_ctrl_in_ready;
    bit trap_ctrl_out_ready;
    bit trap_ctrl_detect_in_ready;
    bit trap_ctrl_detect_out_ready;
    WritePCReq trap_ctrl_write_pc[2];
    WriteCSRReq trap_ctrl_write_csr[3];
    trap_controller trap_controller (
        .clk(clk),
        .rst(rst),

        .pc(pc),

        .op(op),
        .in_ready(trap_ctrl_in_ready),
        .out_ready(trap_ctrl_out_ready),

        .detect_in_ready (trap_ctrl_detect_in_ready),
        .detect_out_ready(trap_ctrl_detect_out_ready),

        .has_exception(op inside {Illegal, EBreak, ECall}),

        .trap_csrs(trap_csrs),
        .write_pc (trap_ctrl_write_pc),
        .write_csr(trap_ctrl_write_csr)
    );

    always_comb begin
        if (need_read_mem) write_reg = write_reg_back;
        else if (execute_alu) write_reg = alu_write_reg;
        else if (execute_fpu) write_reg = fpu_write_reg;
        else if (execute_atomic) write_reg = atom_write_reg;
        else if (execute_csr_unit) write_reg = csr_unit_write_reg;
        else write_reg = {0, 0, IntReg, 0};
    end

    always_comb begin
        read_mem  = {0, 0, Word, IntReg, 0};
        write_mem = {0, 0, Word, 0};

        if (need_read_inst) begin
            read_mem = pc_read_mem;
        end else if (execute_alu) begin
            read_mem  = alu_read_mem;
            write_mem = alu_write_mem;
        end else if (execute_fpu) begin
            read_mem  = fpu_read_mem;
            write_mem = fpu_write_mem;
        end else if (execute_atomic) begin
            read_mem  = atom_read_mem;
            write_mem = atom_write_mem;
        end

        write_reg_back.index = read_mem.target;
        write_reg_back.kind  = read_mem.kind;

        case (read_mem.kind)
            IntReg: begin
                case (read_mem.width)
                    Byte: write_reg_back.val = cache_out_i8;
                    HalfWord: write_reg_back.val = cache_out_i16;
                    Word, DoubleWord: write_reg_back.val = cache_out_i32;
                endcase
            end
            UIntReg: begin
                case (read_mem.width)
                    Byte: write_reg_back.val = cache_out_u8;
                    HalfWord: write_reg_back.val = cache_out_u16;
                    DoubleWord: write_reg_back.val = cache_out_u32;
                endcase
            end
            FloatReg, DoubleReg: write_reg_back.val = cache_out;
        endcase
    end

    always_comb begin
        for (int i = 0; i < $size(trap_ctrl_write_csr); i++) begin
            write_csr[i] = trap_ctrl_write_csr[i];
        end
    end

    always_ff @(posedge clk) begin
        if (rst == 0) begin
            pc <= 0;
            alu_in_ready <= 0;
            fpu_in_ready <= 0;
            atom_in_ready <= 0;
            csr_unit_in_ready <= 0;
            trap_ctrl_in_ready <= 0;
            trap_ctrl_detect_in_ready <= 0;
            state <= Fetch;
        end
    end

    always_ff @(posedge clk) begin
        write_reg_back.enable <= 0;
        pc_read_mem.enable <= 0;

        case (state)
            Fetch: begin
                //禁用所有并行模块
                alu_in_ready <= 0;
                fpu_in_ready <= 0;
                atom_in_ready <= 0;

                pc_read_mem.enable <= 1;
                pc_read_mem.addr <= pc;
                pc <= pc + 4;

                pre_state <= Fetch;
                state <= ReadMem;
            end
            Decode: begin
                alu_in_ready <= 1;
                fpu_in_ready <= 1;
                atom_in_ready <= 1;
                csr_unit_in_ready <= 1;
                trap_ctrl_in_ready <= 1;

                state <= Execute;
            end
            Execute: begin
                pre_state <= Execute;
                //只触发一次
                alu_in_ready <= 0;
                fpu_in_ready <= 0;
                atom_in_ready <= 0;
                csr_unit_in_ready <= 0;
                trap_ctrl_in_ready <= 0;

                //out_ready同时最多只有一个是1
                if (alu_out_ready) begin
                    state <= DetectTrap;
                    if (alu_write_pc.enable) begin
                        pc <= alu_write_pc.val;
                    end
                    if (alu_read_mem.enable) begin
                        state <= ReadMem;
                    end
                    if (alu_write_mem.enable) begin
                        state <= WriteMem;
                    end
                end else if (fpu_out_ready) begin
                    state <= DetectTrap;
                    if (fpu_read_mem.enable) begin
                        state <= ReadMem;
                    end
                    if (fpu_write_mem.enable) begin
                        state <= WriteMem;
                    end
                end else if (atom_out_ready) begin
                    state <= DetectTrap;
                end else if (csr_unit_out_ready) begin
                    state <= DetectTrap;
                end else if (trap_ctrl_out_ready) begin
                    state <= DetectTrap;
                    if (trap_ctrl_write_pc[1].enable) begin
                        pc <= trap_ctrl_write_pc[1].val;
                    end
                end
            end
            ReadMem: begin
                if (read_done) begin
                    case (pre_state)
                        Fetch: begin
                            inst  <= cache_out_u32;
                            state <= Decode;
                        end
                        Execute: begin
                            write_reg_back.enable <= 1;
                            state <= DetectTrap;
                        end
                    endcase
                end
            end
            WriteMem: begin
                if (write_done) begin
                    state <= DetectTrap;
                end
            end
            DetectTrap: begin
                trap_ctrl_detect_in_ready <= 1;
                if (trap_ctrl_detect_out_ready) begin
                    trap_ctrl_detect_in_ready <= 0;
                    state <= Fetch;
                    if (trap_ctrl_write_pc[0].enable) begin
                        pc <= trap_ctrl_write_pc[0].val;
                    end
                end
            end
        endcase
    end
endmodule
