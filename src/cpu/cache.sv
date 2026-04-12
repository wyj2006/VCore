`define CACHE_SIZE 64

module cache (
    input bit clk,
    input bit rst,
    input int unsigned addr,
    input bit [63:0] in,
    input bit we,
    input int unsigned width,
    output bit [63:0] out
);
    bit [7:0] data[`CACHE_SIZE];

    // always_ff @(negedge rst) begin
    //     for (int i = 0; i < `CACHE_SIZE; i = i + 1) data[i] <= 0;
    // end

    always_ff @(posedge clk) begin
        if (we) begin
            case (width)
                1: data[addr] <= in[7:0];
                2: {data[addr+1], data[addr]} <= in[15:0];
                4: {data[addr+3], data[addr+2], data[addr+1], data[addr]} <= in[31:0];
                8:
                {data[addr+7], data[addr+6], data[addr+5], data[addr+4],data[addr+3], data[addr+2], data[addr+1], data[addr]} <= in;
            endcase
        end
    end

    assign out = {
        data[addr+7],
        data[addr+6],
        data[addr+5],
        data[addr+4],
        data[addr+3],
        data[addr+2],
        data[addr+1],
        data[addr]
    };
endmodule
