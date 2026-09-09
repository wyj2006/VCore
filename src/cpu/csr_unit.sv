`include "types.svh"

module csr_unit (
    input bit clk,
    input bit rst,

    input Opcode op,
    input bit [11:0] csr_addr,
    input bit [4:0] rd,
    input bit [4:0] rs1,
    input bit [31:0] a,
    input bit [31:0] imm,

    input  bit in_ready,
    output bit out_ready,

    output WriteRegReq write_reg
);

    bit [31:0] csr[4096];

    enum {
        Idle,
        Run
    } state;

    always_ff @(posedge clk) begin
        write_reg.kind   <= IntReg;
        write_reg.enable <= 0;

        case (state)
            Idle: begin
                out_ready <= 0;
                if (in_ready) state <= Run;
            end
            Run: begin
                state <= Idle;
                out_ready <= 1;

                write_reg.index <= rd;

                case (op)
                    CSRRW: begin
                        write_reg.enable <= 1;
                        write_reg.val <= csr[csr_addr];
                        csr[csr_addr] <= a;
                    end
                    CSRRS: begin
                        write_reg.enable <= 1;
                        write_reg.val <= csr[csr_addr];
                        if (rs1 != 0) csr[csr_addr] <= csr[csr_addr] | a;
                    end
                    CSRRC: begin
                        write_reg.enable <= 1;
                        write_reg.val <= csr[csr_addr];
                        if (rs1 != 0) csr[csr_addr] <= csr[csr_addr] & ~a;
                    end
                    CSRRWI: begin
                        write_reg.enable <= 1;
                        write_reg.val <= csr[csr_addr];
                        csr[csr_addr] <= imm;
                    end
                    CSRRSI: begin
                        write_reg.enable <= 1;
                        write_reg.val <= csr[csr_addr];
                        if (imm != 0) csr[csr_addr] <= csr[csr_addr] | imm;
                    end
                    CSRRCI: begin
                        write_reg.enable <= 1;
                        write_reg.val <= csr[csr_addr];
                        if (imm != 0) csr[csr_addr] <= csr[csr_addr] & ~imm;
                    end
                    default: begin
                        out_ready <= 0;
                    end
                endcase
            end
        endcase
    end

endmodule
