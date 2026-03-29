module pc_reg(input clk,
              input rst,
              input[5:0] flush,
              input[5:0] stall,
              input pc_we,
              input[31:0] pc_new,
              output reg[31:0] pc);
    
    always @(posedge clk or negedge rst) begin
        if (rst == 0)begin
            pc <= 0;
        end
        else begin
            case (1)
                pc_we:pc <= pc_new;
                flush[0]||stall[0]:;
                default:pc <= pc+4;
            endcase
        end
    end
    
endmodule
