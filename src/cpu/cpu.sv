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
        WriteMem
    } State;
    State state;
    State pre_state;

    bit [31:0] pc;

    ReadMemReq read_mem;

    bit [31:0] addr;
    bit [31:0] width;
    bit cache_we;
    bit [63:0] cache_in;
    bit [63:0] cache_out;
    cache cache (
        .clk(clk),
        .rst(rst),
        //atomic模块的请求有更高优先级且不由cpu管理
        .addr(atom_read_mem.enable?atom_read_mem.addr:(atom_write_mem.enable?atom_write_mem.addr:addr)),
        .width(atom_read_mem.enable?atom_read_mem.width:(atom_write_mem.enable?atom_write_mem.width:width)),
        .we(atom_write_mem.enable ? 1 : cache_we),
        .in(atom_write_mem.enable ? atom_write_mem.data : cache_in),
        .out(cache_out)
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
    decoder decoder (
        .inst(inst),
        .op  (op),
        .rd  (rd),
        .rs1 (rs1),
        .rs2 (rs2),
        .imm (imm)
    );

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

    // always_ff @(negedge rst) begin
    //     pc <= 0;
    //     cache_we <= 0;
    //     alu_in_ready <= 0;
    //     fpu_in_ready <= 0;
    //     atom_in_ready <= 0;
    //     state <= Fetch;
    // end

    always_ff @(posedge clk) begin
        pre_state <= state;
        case (state)
            Fetch: begin
                //禁用所有并行模块
                alu_in_ready <= 0;
                fpu_in_ready <= 0;
                atom_in_ready <= 0;
                write_reg.enable <= 0;

                addr <= pc;
                pc <= pc + 4;
                width <= 4;
                cache_we <= 0;

                state <= ReadMem;
            end
            Decode: begin
                alu_in_ready <= 1;
                fpu_in_ready <= 1;
                atom_in_ready <= 1;
                state <= Execute;
            end
            Execute: begin
                //只触发一次
                alu_in_ready  <= 0;
                fpu_in_ready  <= 0;
                atom_in_ready <= 0;
                //out_ready同时最多只有一个是1
                if (alu_out_ready) begin

                    state <= Fetch;
                    if (alu_write_pc.enable) begin
                        pc <= alu_write_pc.val;
                    end
                    if (alu_read_mem.enable) begin
                        addr <= alu_read_mem.addr;
                        width <= alu_read_mem.width;
                        cache_we <= 0;

                        read_mem <= alu_read_mem;

                        state <= ReadMem;
                    end
                    if (alu_write_mem.enable) begin
                        addr <= alu_write_mem.addr;
                        width <= alu_write_mem.width;
                        cache_in <= alu_write_mem.data;
                        cache_we <= 1;

                        state <= WriteMem;
                    end
                    if (alu_write_reg.enable) begin
                        write_reg <= alu_write_reg;
                    end
                end
                if (fpu_out_ready) begin
                    state <= Fetch;
                    if (fpu_read_mem.enable) begin
                        addr <= fpu_read_mem.addr;
                        width <= fpu_read_mem.width;
                        cache_we <= 0;

                        read_mem <= fpu_read_mem;

                        state <= ReadMem;
                    end
                    if (fpu_write_mem.enable) begin
                        addr <= fpu_write_mem.addr;
                        width <= fpu_write_mem.width;
                        cache_in <= fpu_write_mem.data;
                        cache_we <= 1;

                        state <= WriteMem;
                    end
                    if (fpu_write_reg.enable) begin
                        write_reg <= fpu_write_reg;
                    end
                end
                if (atom_out_ready) begin
                    state <= Fetch;
                    if (atom_write_reg.enable) begin
                        write_reg <= fpu_write_reg;
                    end
                end
            end
            ReadMem: begin
                case (pre_state)
                    Fetch: begin
                        inst  <= cache_out_u32;
                        state <= Decode;
                    end
                    Execute: begin
                        write_reg.enable <= 1;
                        write_reg.index  <= read_mem.target;
                        write_reg.kind   <= read_mem.kind;
                        case (read_mem.kind)
                            IntReg: begin
                                case (read_mem.width)
                                    1: write_reg.val <= cache_out_i8;
                                    2: write_reg.val <= cache_out_i16;
                                    4: write_reg.val <= cache_out_i32;
                                endcase
                            end
                            UIntReg: begin
                                case (read_mem.width)
                                    1: write_reg.val <= cache_out_u8;
                                    2: write_reg.val <= cache_out_u16;
                                    4: write_reg.val <= cache_out_u32;
                                endcase
                            end
                            FloatReg, DoubleReg: write_reg.val <= cache_out[31:0];
                        endcase
                        state <= Fetch;
                    end
                endcase
            end
            WriteMem: begin
                cache_we <= 0;
                state <= Fetch;
            end
        endcase
    end
endmodule
