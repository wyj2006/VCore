`include "inst_def.vh"

module exs(input clk,
           input rst,
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
           output reg[31:0] pc_new,
           output reg[5:0] stall_req);
    
    wire [63:0] signed_64_a   = $signed(a);
    wire [63:0] signed_64_b   = $signed(b);
    wire [63:0] unsigned_64_a = $unsigned(a);
    wire [63:0] unsigned_64_b = $unsigned(b);
    //s表示有符号, u表示无符号
    wire [63:0] ss_result = signed_64_a*signed_64_b;
    wire [63:0] su_result = signed_64_a*unsigned_64_b;
    wire [63:0] uu_result = unsigned_64_a*unsigned_64_b;
    
    reg [31:0] dividend;
    reg [31:0] divisor;
    reg [7:0] divrem_op;
    reg divrem_en;
    reg [6:0] divrem_left;//距离计算出结果还有多少个周期
    wire [63:0] divrem_s_result;
    wire [63:0] divrem_u_result;
    
    div_signed div_signed(
    .aclk(clk),
    .s_axis_dividend_tdata(dividend),
    .s_axis_divisor_tdata(divisor),
    .s_axis_dividend_tvalid(1),
    .s_axis_divisor_tvalid(1),
    .m_axis_dout_tdata(divrem_s_result),
    .aclken(divrem_en)
    );
    
    div_unsigned div_unsigned(
    .aclk(clk),
    .s_axis_dividend_tdata(dividend),
    .s_axis_divisor_tdata(divisor),
    .s_axis_dividend_tvalid(1),
    .s_axis_divisor_tvalid(1),
    .m_axis_dout_tdata(divrem_u_result),
    .aclken(divrem_en)
    );
    
    always @(negedge rst) begin
        stall_req <= 0;
    end
    
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
                dividend  <= a;
                divisor   <= b;
                divrem_en <= 0;
                ulrw      <= 0;
                rd_we     <= 0;
                pc_we     <= 0;
                rd_from   <= rd_to;
                divrem_op <= op;
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
                    `MUL:begin
                        result <= ss_result[31:0];
                        rd_we  <= 1;
                    end
                    `MULH:begin
                        result <= ss_result[63:32];
                        rd_we  <= 1;
                    end
                    `MULHSU:begin
                        result <= su_result[63:32];
                        rd_we  <= 1;
                    end
                    `MULHU:begin
                        result <= uu_result[63:32];
                        rd_we  <= 1;
                    end
                    `DIV,`REM:begin
                        divrem_en   <= 1;
                        divrem_left <= 36;
                        stall_req   <= 'b111111;
                    end
                    `DIVU,`REMU:begin
                        divrem_en   <= 1;
                        divrem_left <= 34;
                        stall_req   <= 'b111111;
                    end
                    default:;
                endcase
            end
        endcase
    end
    
    always @(posedge clk) begin
        if (divrem_en == 1)begin
            divrem_left <= divrem_left-1;
            if (divrem_left == 0)begin
                stall_req <= 0;
                divrem_en <= 0;
                rd_we     <= 1;
                case(divrem_op)
                    `DIV:begin
                        result <= divrem_s_result[63:32];
                    end
                    `DIVU:begin
                        result <= divrem_u_result[63:32];
                    end
                    `REM:begin
                        result <= divrem_s_result[31:0];
                    end
                    `REMU:begin
                        result <= divrem_u_result[31:0];
                    end
                endcase
            end
        end
    end
endmodule
