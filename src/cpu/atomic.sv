`include "types.svh"

//rv32a的实现
module atomic (
    input bit clk,
    input bit rst,

    input Opcode op,
    input bit [4:0] rd,
    input bit [31:0] a,
    input bit [31:0] b,

    input  bit in_ready,
    output bit out_ready,

    input bit [63:0] cache_out,

    output ReadMemReq  read_mem,
    output WriteMemReq write_mem,
    output WriteRegReq write_reg
);
    enum {
        Idle,
        Run,
        ReadMem,
        Calculate,
        WriteMem
    } state;

    bit [31:0] temp;

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
                read_mem.target <= rd;

                write_reg.kind  <= IntReg;
                write_reg.index <= rd;

                case (op)
                    LRW, AMOSwapW,AMOAddW,AMOXorW,AMOAndW,AMOOrW,AMOMinW,AMOMaxW,AMOMinUW,AMOMaxUW: begin
                        //TODO 保留标志
                        read_mem.enable <= 1;
                        read_mem.addr <= a;
                        read_mem.kind <= IntReg;
                        read_mem.width <= Word;
                        read_mem.target <= rd;

                        out_ready <= 0;
                        state <= ReadMem;
                    end
                    SCW: begin
                        //TODO 保留标志
                        write_mem.enable <= 1;
                        write_mem.addr <= a;
                        write_mem.data <= b;
                        write_mem.width <= Word;

                        write_reg.enable <= 1;
                        write_reg.val <= 0;

                        out_ready <= 0;
                        state <= WriteMem;
                    end
                    default: begin
                        out_ready <= 0;
                        state <= Idle;
                    end
                endcase
            end
            ReadMem: begin
                case (op)
                    LRW: begin
                        write_reg.enable <= 1;
                        write_reg.val <= cache_out;
                        //write_reg的其它属性在之前的状态中已经设置过
                        out_ready <= 1;
                        state <= Idle;
                    end
                    AMOSwapW,AMOAddW,AMOXorW,AMOAndW,AMOOrW,AMOMinW,AMOMaxW,AMOMinUW,AMOMaxUW:begin
                        temp  <= cache_out;
                        state <= Calculate;
                    end
                endcase
            end
            Calculate: begin
                write_reg.enable <= 1;
                write_reg.val <= temp;
                //write_reg的其它属性在之前的状态中已经设置过

                write_mem.enable <= 1;
                write_mem.addr <= a;
                write_mem.width <= Word;
                state <= WriteMem;
                case (op)
                    AMOSwapW: write_mem.data <= b;
                    AMOAddW:  write_mem.data <= temp + b;
                    AMOXorW:  write_mem.data <= temp ^ b;
                    AMOAndW:  write_mem.data <= temp & b;
                    AMOOrW:   write_mem.data <= temp | b;
                    AMOMinW:  write_mem.data <= $signed(temp) > $signed(b) ? b : temp;
                    AMOMaxW:  write_mem.data <= $signed(temp) < $signed(b) ? b : temp;
                    AMOMinUW: write_mem.data <= $unsigned(temp) > $unsigned(b) ? b : temp;
                    AMOMaxUW: write_mem.data <= $unsigned(temp) < $unsigned(b) ? b : temp;
                endcase
            end
            WriteMem: begin
                //如果从Calculate转换而来, 这个阶段会写入内存和寄存器
                out_ready <= 1;
                state <= Idle;
            end
        endcase
    end
endmodule
