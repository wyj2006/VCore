`include "types.svh"

module csr_unit (
    input bit clk,
    input bit rst,

    //来自指令的修改请求
    input Opcode op,
    input bit [11:0] csr_addr,
    input bit [4:0] rd,
    input bit [4:0] rs1,
    input bit [31:0] a,
    input bit [31:0] imm,

    input  bit in_ready,
    output bit out_ready,

    //来自其它部分的修改请求
    input WriteCSRReq ext_write_csr[3],

    output TrapRelatedCSRs trap_csrs,
    output WriteRegReq write_reg
);

    bit [31:0] rdata;

    bit [31:0] mstatus;
    bit [31:0] mie;
    bit [31:0] mtvec;
    bit [31:0] mepc;
    bit [31:0] mip;

    WriteCSRReq in_write_csr;  //内部修改请求
    WriteCSRReq write_csr[3];

    assign trap_csrs.mstatus = mstatus;
    assign trap_csrs.mie = mie;
    assign trap_csrs.mtvec = mtvec;
    assign trap_csrs.mepc = mepc;
    assign trap_csrs.mip = mip;

    always_comb begin : blockName
        write_csr[0] = in_write_csr;
        for (int i = 0; i < $size(ext_write_csr); i++) begin
            write_csr[i+1] = ext_write_csr[i];
        end
    end

    always_comb begin
        case (csr_addr)
            `MSTATUS_ADDR: rdata = mstatus;
            `MIE_ADDR: rdata = mie;
            `MTVEC_ADDR: rdata = mtvec;
            `MEPC_ADDR: rdata = mepc;
            `MIP_ADDR: rdata = mip;
            default: rdata = 0;
        endcase
    end

    always @(posedge clk) begin
        for (int i = 0; i < $size(write_csr); i++) begin
            if (!write_csr[i].enable) continue;
            case (write_csr[i].addr)
                `MSTATUS_ADDR: mstatus <= write_csr[i].val;
                `MIE_ADDR: mie <= write_csr[i].val;
                `MTVEC_ADDR: mtvec <= write_csr[i].val;
                `MEPC_ADDR: mepc <= write_csr[i].val;
                `MIP_ADDR: mip <= write_csr[i].val;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        write_reg.kind <= IntReg;
        write_reg.enable <= 0;
        write_reg.index <= rd;
        in_write_csr.enable <= 0;
        out_ready <= 0;

        if (in_ready) begin
            out_ready <= 1;

            case (op)
                CSRRW: begin
                    write_reg.enable <= 1;
                    write_reg.val <= rdata;

                    in_write_csr.enable <= 1;
                    in_write_csr.addr <= csr_addr;
                    in_write_csr.val <= a;
                end
                CSRRS: begin
                    write_reg.enable <= 1;
                    write_reg.val <= rdata;

                    in_write_csr.enable <= 1;
                    in_write_csr.addr <= csr_addr;
                    in_write_csr.val <= rdata | a;
                end
                CSRRC: begin
                    write_reg.enable <= 1;
                    write_reg.val <= rdata;

                    in_write_csr.enable <= 1;
                    in_write_csr.addr <= csr_addr;
                    in_write_csr.val <= rdata & ~a;
                end
                CSRRWI: begin
                    write_reg.enable <= 1;
                    write_reg.val <= rdata;

                    in_write_csr.enable <= 1;
                    in_write_csr.addr <= csr_addr;
                    in_write_csr.val <= imm;
                end
                CSRRSI: begin
                    write_reg.enable <= 1;
                    write_reg.val <= rdata;

                    if (imm != 0) begin
                        in_write_csr.enable <= 1;
                        in_write_csr.addr <= csr_addr;
                        in_write_csr.val <= rdata | imm;
                    end
                end
                CSRRCI: begin
                    write_reg.enable <= 1;
                    write_reg.val <= rdata;

                    if (imm != 0) begin
                        in_write_csr.enable <= 1;
                        in_write_csr.addr <= csr_addr;
                        in_write_csr.val <= rdata & ~imm;
                    end
                end
                default: begin
                    out_ready <= 0;
                end
            endcase
        end
    end

endmodule
