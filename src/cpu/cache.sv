`include "types.svh"

`define CACHE_SIZE 1024

module cache (
    input bit clk,
    input bit rst,

    input bit [31:0] read_addr,
    input bit read_enable,
    input DataWidth read_width,
    output bit [63:0] read_data,
    output bit read_done,

    input bit [31:0] write_addr,
    input bit [63:0] write_data,
    input DataWidth write_width,
    input bit write_enable,
    output bit write_done
);
    enum {
        ReadIdle,
        WaitRead0,
        WaitRead1
    } read_state;

    enum {
        WriteIdle,
        WaitWrite0,
        WaitWrite1
    } write_state;

    bit [15:0] write_end_addr;
    bit [15:0] addra;
    bit clka;
    bit [63:0] dina;
    bit ena;
    bit [7:0] wea;

    bit [15:0] addrb;
    bit clkb;
    bit [63:0] doutb;
    bit enb;
    bit [1:0] clkb_count;

    assign clkb = clk;
    assign clka = clk;

    internal_bram internal_bram (
        .addra(addra),
        .clka (clka),
        .dina (dina),
        .ena  (ena),
        .wea  (wea),

        .addrb(addrb),
        .clkb (clkb),
        .doutb(doutb),
        .enb  (enb)
    );

    always_ff @(posedge clk) begin
        if (rst == 0) begin
            ena <= 0;
            enb <= 0;
            read_done <= 0;
            write_done <= 0;
            read_state <= ReadIdle;
            write_state <= WriteIdle;
        end
    end

    always @(posedge clk) begin
        read_done <= 0;

        case (read_state)
            ReadIdle: begin
                if (read_enable) begin
                    addrb <= read_addr >> 3;
                    clkb_count <= 0;
                    enb <= 1;
                    read_state <= WaitRead0;
                end
            end
            WaitRead0: begin
                if (clkb_count == 2) begin
                    read_data <= doutb >> (read_addr[2:0] * 8);
                    if ((read_addr >> 3) != ((read_addr + read_width) >> 3)) begin
                        //跨越边界
                        read_state <= WaitRead1;
                        addrb <= (read_addr >> 3) + 1;
                        clkb_count <= 0;
                    end else begin
                        read_state <= ReadIdle;
                        enb <= 0;
                        read_done <= 1;
                    end
                end else begin
                    clkb_count <= clkb_count + 1;
                end
            end
            WaitRead1: begin
                if (clkb_count == 2) begin
                    read_state <= ReadIdle;
                    enb <= 0;
                    read_done <= 1;
                    read_data <= read_data | (doutb << (64 - read_addr[2:0] * 8));
                end else begin
                    clkb_count <= clkb_count + 1;
                end
            end
        endcase
    end

    always_ff @(posedge clk) begin
        write_done <= 0;

        case (write_state)
            WriteIdle: begin
                if (write_enable) begin
                    write_state <= WaitWrite0;
                    addra <= write_addr >> 3;
                    dina <= write_data << (write_addr[2:0] * 8);
                    ena <= 1;
                    case (write_width)
                        Byte: wea <= 8'b00000001 << write_addr[2:0];
                        HalfWord: wea <= 8'b00000011 << write_addr[2:0];
                        Word: wea <= 8'b00001111 << write_addr[2:0];
                        DoubleWord: wea <= 8'b11111111 << write_addr[2:0];
                        default: wea <= 8'b00000000;
                    endcase
                end
            end
            WaitWrite0: begin
                if ((write_addr >> 3) != ((write_addr + write_width) >> 3)) begin
                    //跨越边界
                    write_state <= WaitWrite1;
                    addra <= (write_addr >> 3) + 1;
                    dina <= write_data >> (64 - write_addr[2:0] * 8);
                    case (write_width)
                        Byte: wea <= 8'b00000001 >> (8 - write_addr[2:0]);
                        HalfWord: wea <= 8'b00000011 >> (8 - write_addr[2:0]);
                        Word: wea <= 8'b00001111 >> (8 - write_addr[2:0]);
                        DoubleWord: wea <= 8'b11111111 >> (8 - write_addr[2:0]);
                        default: wea <= 8'b00000000;
                    endcase
                end else begin
                    write_state <= WriteIdle;
                    ena <= 0;
                    write_done <= 1;
                end
            end
            WaitWrite1: begin
                write_state <= WriteIdle;
                ena <= 0;
                write_done <= 1;
            end
        endcase
    end

endmodule
