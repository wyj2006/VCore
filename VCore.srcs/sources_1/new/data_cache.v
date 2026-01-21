`define DATA_CACHE_SIZE 1024

module data_cache(input clk,
                  input rst,
                  input[31:0] raddr,
                  output[31:0] rdata,
                  input we,
                  input[2:0] len,
                  input unsigned_ext,
                  input[31:0] waddr,
                  input[31:0] wdata);
    
    `define BYTE cache[raddr]
    `define HALF {cache[raddr+1],cache[raddr]}
    `define WORD {cache[raddr+3],cache[raddr+2],cache[raddr+1],cache[raddr]}
    
    reg[7:0] cache[`DATA_CACHE_SIZE-1:0];
    
    integer i;
    
    assign rdata = unsigned_ext?$unsigned(len == 1?`BYTE:len == 2?`HALF:`WORD):$signed(len == 1?`BYTE:len == 2?`HALF:`WORD);
    
    always @(posedge clk or negedge rst) begin
        if (rst == 0)begin
            for(i = 0;i<`DATA_CACHE_SIZE;i = i+1)begin
                cache[i] <= 0;
            end
        end
        else if (we) begin
            case(len)
                1:cache[waddr]                                                      <= wdata;
                2:{cache[waddr+1],cache[waddr]}                                     <= wdata;
                default:{cache[waddr+3],cache[waddr+2],cache[waddr+1],cache[waddr]} <= wdata;
            endcase
        end
        else begin
        end
    end
    
endmodule
