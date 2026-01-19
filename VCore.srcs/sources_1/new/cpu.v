module cpu(input clk,
           input rst);
    
    reg[7:0] state = 0;
    
    reg[31:0] pc;
    
    wire[31:0] inst_from;
    reg[31:0] inst_to;
    
    wire we_from;
    reg we_to = 0;
    
    wire[4:0] rd_from[3:0];
    reg[4:0] rd_to[3:0];
    
    wire[31:0] a_from;
    reg[31:0] a_to;
    
    wire[31:0] b_from;
    reg[31:0] b_to;
    
    wire[31:0] imm_from;
    reg[31:0] imm_to;
    
    wire[31:0] op_from;
    reg[31:0] op_to;
    
    wire rd_we_from[3:0];
    reg rd_we_to[3:0];
    
    wire[1:0] rw_from;
    reg[1:0] rw_to;
    
    wire[31:0] data_from[3:0];
    reg[31:0] data_to[3:0];
    
    wire[31:0] addr_from;
    reg[31:0] addr_to;
    
    ifs ifs(
    .clk(clk),
    .rst(rst),
    .pc(pc),
    .inst(inst_from)
    );
    
    ids ids(
    .clk(clk),
    .rst(rst),
    .inst(inst_to),
    .we(we_to),
    .rd_to(rd_to[0]),
    .wdata(data_to[0]),
    .a(a_from),
    .b(b_from),
    .imm(imm_from),
    .op(op_from),
    .rd_from(rd_from[0])
    );
    
    exs exs(
    .clk(clk),
    .a(a_to),
    .b(b_to),
    .imm(imm_to),
    .op(op_to),
    .rd_to(rd_to[1]),
    .rd_from(rd_from[1]),
    .rd_we(rd_we_from[1]),
    .addr(addr_from),
    .rw(rw_from),
    .data(data_from[1])
    );
    
    mems mems(
    .clk(clk),
    .rd_we_to(rd_we_to[2]),
    .rw(rw_to),
    .addr(addr_to),
    .wdata(data_to[2]),
    .rd_to(rd_to[2]),
    .rd_from(rd_from[2]),
    .rd_we_from(rd_we_from[2]),
    .data(data_from[2])
    );
    
    wbs wbs(
    .clk(clk),
    .rd_to(rd_to[3]),
    .rd_we(rd_we_to[3]),
    .data_to(data_to[3]),
    .rd_from(rd_from[3]),
    .we_from(we_from),
    .data_from(data_from[3])
    );
    
    always @(posedge clk or negedge rst) begin
        if (rst == 0)begin
            state <= 0;
            pc    <= 0;
        end
        else begin
            case (state)
                1:begin
                    we_to <= 0;
                    
                    inst_to <= inst_from;
                    
                    state <= state+1;
                end
                3:begin
                    a_to     <= a_from;
                    b_to     <= b_from;
                    op_to    <= op_from;
                    imm_to   <= imm_from;
                    rd_to[1] <= rd_from[0];
                    
                    state <= state+1;
                end
                5:begin
                    rd_to[2]    <= rd_from[1];
                    rd_we_to[2] <= rd_we_from[1];
                    addr_to     <= addr_from;
                    data_to[2]  <= data_from[1];
                    rw_to       <= rw_from;
                    
                    state <= state+1;
                end
                7:begin
                    rd_to[3]    <= rd_from[2];
                    rd_we_to[3] <= rd_we_from[2];
                    data_to[3]  <= data_from[2];
                    
                    state <= state+1;
                end
                9:begin
                    rd_to[0]   <= rd_from[3];
                    we_to      <= we_from;
                    data_to[0] <= data_from[3];
                    
                    state <= 0;
                    pc    <= pc+4;
                end
                default:state <= state+1;
            endcase
        end
    end
    
endmodule
