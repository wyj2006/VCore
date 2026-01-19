module mems(input clk,
            input rd_we_to,
            input[1:0] rw,
            input[31:0] addr,
            input[31:0] wdata,
            input[4:0] rd_to,
            output[4:0] rd_from,
            output rd_we_from,
            output[31:0] data);
    
    wire we;
    wire[31:0] rdata;
    
    data_cache data_cache(
    .clk(clk),
    .we(we),
    .addr(addr),
    .wdata(wdata),
    .rdata(rdata)
    );
    
    assign rd_we_from = rd_we_to;
    assign we         = rw == 'b01;
    assign rd_from    = rd_to;
    assign data       = (rw == 'b10)?rdata:wdata;
    
endmodule
