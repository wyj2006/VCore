`timescale 1ns / 100ps
`include "../cpu/types.svh"

module tb_cache ();
    bit clk = 0;
    bit rst = 1;

    bit [31:0] read_addr;
    bit read_enable = 0;
    DataWidth read_width;
    bit [63:0] read_data;
    bit read_done;

    bit [31:0] write_addr;
    bit [63:0] write_data;
    DataWidth write_width;
    bit write_enable = 0;
    bit write_done;

    cache cache (
        .clk(clk),
        .rst(rst),

        .read_addr  (read_addr),
        .read_enable(read_enable),
        .read_width (read_width),
        .read_data  (read_data),
        .read_done  (read_done),

        .write_addr  (write_addr),
        .write_data  (write_data),
        .write_width (write_width),
        .write_enable(write_enable),
        .write_done  (write_done)
    );

    always #0.5 clk = ~clk;

    initial begin
        #0.5;
        rst = 0;
        #1;
        rst = 1;

        #1;

        write_addr   = 1;
        write_data   = 64'h1234567890abcdef;
        write_width  = DoubleWord;
        write_enable = 1;
        #1;
        write_enable = 0;
        #5;

        read_addr   = 4;
        read_enable = 1;
        read_width  = DoubleWord;
        #1;
        read_enable = 0;
        #10;
        $finish;
    end
endmodule
