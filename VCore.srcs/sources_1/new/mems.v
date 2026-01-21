module mems(input clk,
            input rst,
            input[5:0] flush,
            input[5:0] stall,
            input rd_we_to,
            output[5:0] ulrw_to,
            input[31:0] addr,
            input[31:0] data_to,
            input[4:0] rd_to,
            output reg[4:0] rd_from,
            output reg rd_we_from,
            output reg[5:0] ulrw_from,
            output reg[31:0] data_from);
    
    wire[31:0] rdata;
    
    data_cache data_cache(
    .clk(clk),
    .rst(rst),
    .raddr(addr),
    .rdata(rdata),
    .we(flush[4] == 0&&stall[4] == 0?ulrw_to[1:0] == 'b01:0),
    .len(ulrw_to[4:2]),
    .unsigned_ext(ulrw_to[5]),
    .waddr(addr),
    .wdata(data_to)
    );
    
    always @(posedge clk) begin
        case(1)
            flush[4]:begin
                rd_we_from <= 0;
                ulrw_from  <= 0;
                rd_from    <= 0;
                data_from  <= 0;
            end
            stall[4]:;
            default:begin
                rd_we_from <= rd_we_to;
                ulrw_from  <= ulrw_to;
                rd_from    <= rd_to;
                if (ulrw_to[1:0] == 'b10)begin
                    data_from <= rdata;
                end
                else begin
                    data_from <= data_to;
                end
            end
        endcase
    end
    
endmodule
