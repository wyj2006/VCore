module wbs(input clk,
           input[4:0] rd_to,
           input rd_we,
           input [31:0] data_to,
           output[4:0] rd_from,
           output we_from,
           output[31:0] data_from);
    
    assign we_from   = rd_we;
    assign rd_from   = rd_to;
    assign data_from = data_to;
    
endmodule
