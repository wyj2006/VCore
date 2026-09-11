`include "types.svh"

module trap_controller (
    input bit clk,
    input bit rst,

    input bit [31:0] pc,

    input Opcode op,
    input bit in_ready,
    output bit out_ready,

    input  bit detect_in_ready,
    output bit detect_out_ready,

    input bit has_exception,

    output TrapRelatedCSRs trap_csrs,
    output WritePCReq write_pc[2],
    output WriteCSRReq write_csr[3]
);

    bit [31:0] mstatus;
    bit mstatus_mie;
    bit [31:0] mie, mip;
    bit [31:0] mepc, mtvec;
    bit msie, msip;  //软件中断

    assign mstatus = trap_csrs.mstatus;
    assign mstatus_mie = mstatus[3];
    assign mie = trap_csrs.mie;
    assign mip = trap_csrs.mip;
    assign msie = mie[3];
    assign msip = mip[3];
    assign mepc = trap_csrs.mepc;
    assign mtvec = trap_csrs.mtvec;

    always @(posedge clk) begin
        out_ready <= 0;
        detect_out_ready <= 0;
        for (int i = 0; i < $size(write_pc); i++) begin
            write_pc[i].enable <= 0;
        end
        for (int i = 0; i < $size(write_csr); i++) begin
            write_csr[i].enable <= 0;
        end

        if (in_ready) begin
            case (op)
                MRet: begin
                    out_ready <= 1;

                    write_pc[1].enable <= 1;
                    write_pc[1].val <= mepc;

                    write_csr[0].enable <= 1;
                    write_csr[0].addr <= `MSTATUS_ADDR;
                    write_csr[0].val <= {mstatus[31:4], mstatus[7], mstatus[2:0]};
                    //TODO 设置权限
                end
                Illegal: begin
                    write_csr[0].enable <= 1;
                    write_csr[0].addr <= `MCAUSE_ADDR;
                    write_csr[0].val <= 2;
                end
                ECall: begin
                    write_csr[0].enable <= 1;
                    write_csr[0].addr <= `MCAUSE_ADDR;
                    write_csr[0].val <= 11;
                end
                EBreak: begin
                    write_csr[0].enable <= 1;
                    write_csr[0].addr <= `MCAUSE_ADDR;
                    write_csr[0].val <= 3;
                end
            endcase
        end else if (detect_in_ready) begin
            detect_out_ready <= 1;

            if ((mstatus_mie && (mie & mip)) || has_exception) begin
                write_csr[0].enable <= 1;
                write_csr[0].addr <= `MEPC_ADDR;
                write_csr[0].val <= pc;

                write_pc[0].enable <= 1;
                write_pc[0].val <= mtvec;

                write_csr[1].enable <= 1;
                write_csr[1].addr <= `MSTATUS_ADDR;
                write_csr[1].val <= {mstatus[31:8], mstatus_mie, mstatus[6:4], 1'b0, mstatus[2:0]};
                //TODO 设置权限

                write_csr[2].enable <= 1;
                write_csr[2].addr <= `MCAUSE_ADDR;

                if (msie && msip) write_csr[2].val <= 32'h80000003;
                else if (!has_exception) write_csr[2].val <= 0;

            end
        end
    end

endmodule
