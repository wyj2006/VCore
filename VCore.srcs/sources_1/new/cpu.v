module cpu(input clk,
           input rst);
    
    wire[5:0] flush;
    wire[5:0] stall;
    wire[1:0] forward_ex_mem;
    wire[1:0] forward_mem_wb;
    
    wire pc_we_exs;
    wire[31:0] pc_new_exs;
    wire[31:0] pc;
    
    wire[31:0] inst;
    
    wire[4:0] rs1;
    wire[4:0] rs2;
    wire[31:0] imm;
    wire[7:0] op;
    wire[4:0] rd[4:0];
    
    wire[31:0] a;
    wire[31:0] b;
    wire[31:0] result;
    wire[31:0] addr;
    wire rd_we[4:0];
    wire[5:0] ulrw[4:0];
    
    wire[31:0] data[4:0];
    
    cu cu(
    .clk(clk),
    .rst(rst),
    .op(op),
    .id_ex_rs1(rs1),
    .id_ex_rs2(rs2),
    .ex_mem_rd(rd[2]),
    .ex_mem_rd_we(rd_we[2]),
    .ex_mem_ulrw(ulrw[2]),
    .mem_wb_rd(rd[3]),
    .mem_wb_rd_we(rd_we[3]),
    .mem_wb_ulrw(ulrw[3]),
    .flush(flush),
    .stall(stall),
    .forward_ex_mem(forward_ex_mem),
    .forward_mem_wb(forward_mem_wb)
    );
    
    pc_reg pc_reg(
    .clk(clk),
    .rst(rst),
    .flush(flush),
    .stall(stall),
    .pc_we(pc_we_exs),
    .pc_new(pc_new_exs),
    .pc(pc)
    );
    
    ifs ifs(
    .clk(clk),
    .rst(rst),
    .flush(flush),
    .stall(stall),
    .pc(pc),
    .inst(inst)
    );
    
    ids ids(
    .clk(clk),
    .flush(flush),
    .stall(stall),
    .inst(inst),
    .rs1(rs1),
    .rs2(rs2),
    .imm(imm),
    .op(op),
    .rd(rd[1])
    );
    
    regfile regfile(
    .clk(clk),
    .rst(rst),
    .raddr1(rs1),
    .rdata1(a),
    .raddr2(rs2),
    .rdata2(b),
    .we(rd_we[4]),
    .waddr(rd[4]),
    .wdata(data[4])
    );
    
    exs exs(
    .clk(clk),
    .flush(flush),
    .stall(stall),
    .pc(pc),
    .a(forward_ex_mem[0]?result:forward_mem_wb[0]?data[3]:a),
    .b(forward_ex_mem[1]?result:forward_mem_wb[1]?data[3]:b),
    .imm(imm),
    .op(op),
    .rd_to(rd[1]),
    .rd_from(rd[2]),
    .rd_we(rd_we[2]),
    .ulrw(ulrw[2]),
    .result(result),
    .addr(addr),
    .pc_we(pc_we_exs),
    .pc_new(pc_new_exs)
    );
    
    mems mems(
    .clk(clk),
    .rst(rst),
    .flush(flush),
    .stall(stall),
    .rd_we_to(rd_we[2]),
    .ulrw_to(ulrw[2]),
    .addr(addr),
    .data_to(result),
    .rd_to(rd[2]),
    .rd_from(rd[3]),
    .rd_we_from(rd_we[3]),
    .ulrw_from(ulrw[3]),
    .data_from(data[3])
    );
    
    wbs wbs(
    .clk(clk),
    .flush(flush),
    .stall(stall),
    .rd_we_to(rd_we[3]),
    .ulrw_to(ulrw[3]),
    .rd_to(rd[3]),
    .data_to(data[3]),
    .rd_from(rd[4]),
    .rd_we_from(rd_we[4]),
    .ulrw_from(ulrw[4]),
    .data_from(data[4])
    );
    
endmodule
