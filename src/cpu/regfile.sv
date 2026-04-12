`include "types.svh"

module regfile (
    input bit clk,
    input bit rst,
    //读取寄存器所需的端口
    input bit [4:0] index[4],
    input RegKind kind[4],
    output bit [63:0] value[4],

    input WriteRegReq write_reg
);

    bit [31:0] x[`INT_REG_NUM];
    bit [63:0] f[ `FP_REG_NUM];

    assign x[0] = 0;

    always_comb begin
        for (int i = 0; i < 4; i = i + 1) begin
            case (kind[i])
                IntReg, UIntReg: value[i] = x[index[i]];
                FloatReg, DoubleReg: value[i] = f[index[i]];
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (write_reg.enable) begin
            case (write_reg.kind)
                IntReg, UIntReg: begin
                    if (write_reg.index != 0) begin
                        x[write_reg.index] <= write_reg.val[31:0];
                    end
                end
                FloatReg:  f[write_reg.index][31:0] <= write_reg.val[31:0];
                DoubleReg: f[write_reg.index] <= write_reg.val;
            endcase
        end
    end

endmodule
