module wbs(input clk,
           input[5:0] flush,
           input[5:0] stall,
           input rd_we_to,
           input[5:0] ulrw_to,
           input[31:0] data_to,
           input[4:0] rd_to,
           output[4:0] rd_from,
           output[31:0] data_from,
           output rd_we_from,
           output[5:0] ulrw_from);
    
    assign rd_we_from = flush[5]?0:stall[5]?rd_we_from:rd_we_to;
    assign ulrw_from  = flush[5]?0:stall[5]?ulrw_from:ulrw_to;
    assign rd_from    = flush[5]?0:stall[5]?rd_from:rd_to;
    assign data_from  = flush[5]?0:stall[5]?data_from:data_to;
    
endmodule
