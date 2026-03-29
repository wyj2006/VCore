module ifs(input clk,
           input rst,
           input[5:0] flush,
           input[5:0] stall,
           input[31:0] pc,
           output reg[31:0] inst);
    
    wire[31:0] next_inst;
    
    inst_cache inst_cache(
    .clk(clk),
    .rst(rst),
    .pc(pc),
    .inst(next_inst)
    );
    
    always @(posedge clk) begin
        case(1)
            flush[1]:inst <= 'h00000013;//nop
            stall[1]:;
            default:inst <= next_inst;
        endcase
    end
    
endmodule
