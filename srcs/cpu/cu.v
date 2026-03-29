`include "inst_def.vh"

module cu(input clk,
          input rst,
          input [5:0] stall_req,
          input pc_we,
          input[4:0] id_ex_rs1,
          input[4:0] id_ex_rs2,
          input[4:0] ex_mem_rd,
          input ex_mem_rd_we,
          input[5:0] ex_mem_ulrw,
          input[4:0] mem_wb_rd,
          input mem_wb_rd_we,
          input[5:0] mem_wb_ulrw,
          output[5:0] flush,
          output[5:0] stall,
          output[1:0] forward_ex_mem,
          output[1:0] forward_mem_wb);
    
    //如果要求全部阻塞的话就暂时不清空
    assign flush = !(stall_req == 'b111111)&&pc_we == 1?'b001111:0;
    assign stall = !(stall_req == 0)?stall_req:ex_mem_ulrw[1:0] == 2'b10&&(ex_mem_rd == id_ex_rs1||ex_mem_rd == id_ex_rs2)?'b001111:0;
    //TODO 防止误判
    assign forward_ex_mem[0] = ex_mem_rd_we&&ex_mem_rd == id_ex_rs1;
    assign forward_ex_mem[1] = ex_mem_rd_we&&ex_mem_rd == id_ex_rs2;
    
    assign forward_mem_wb[0] = mem_wb_rd_we&&mem_wb_rd == id_ex_rs1;
    assign forward_mem_wb[1] = mem_wb_rd_we&&mem_wb_rd == id_ex_rs2;
    
endmodule
