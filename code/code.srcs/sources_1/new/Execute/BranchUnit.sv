`include "../InstructionDecode/IDPhaseStruct.svh"
`include "../InstructionFetch/IFPhaseConfig.svh"
`include "../RegisterRenaming/RRPhaseConfig.svh"
`include "../Issue/IssuePhaseStruct.svh"
`include "../Issue/IssuePhaseConfig.svh"

// the main funtion of the branch unit is to verify whether the predicted result is right
module BranchUnit #(
    
) (
    input IQEntry iq_entry,
    input PayloadEntry payload,
    input wire [`ROB_INDEX_WIDTH-1: 0] bc_robid,
    input wire [`REG_WIDTH-1: 0] bc_value [`ISSUE_WIDTH],
    output wire mispred,
    output wire do_jump,
    output wire [`INST_ADDR_WIDTH-1: 0] actual_addr,
    output wire write_back, // 该单元计算得到的结果是否需要写回
    output wire [`REG_WIDTH-1: 0] result,  // 计算结果
    output wire [`ROB_INDEX_WIDTH-1: 0] wb_robid // 需要写到哪个 robid (同时将放到广播通路上)
);
    
reg reg_do_jump;
reg [`INST_ADDR_WIDTH-1: 0] reg_actual_addr;
assign do_jump = reg_do_jump;
assign actual_addr = reg_actual_addr;

reg [`REG_WIDTH-1: 0] srcL_value;
reg [`REG_WIDTH-1: 0] srcR_value;

reg reg_write_back;
reg [`REG_WIDTH-1: 0] reg_result;
reg [`ROB_INDEX_WIDTH-1: 0] reg_wb_robid;
assign write_back = reg_write_back;
assign result = reg_result;
assign wb_robid = reg_wb_robid;

// just need to use combinatorial logic
always_comb begin
    // $assert (inst_info_in.op_type == BRANCH) 
    // else   $display("misdispatch instruction %h to branch unit", );

    // 获取 srcL 和 srcR 的值（如果需要的话）
    // srcL: 
    if (iq_entry.inst_info.srcL_valid) begin 
        // 通过 payload 读取
        if (iq_entry.pr_srcL_ready) begin 
            srcL_value = payload.srcL_value;
        end 
        // 通过旁路广播读取
        else if (iq_entry.bc_srcL_ready) begin 
            for (int i = 0; i < `ISSUE_WIDTH; i += 1) begin 
                if (iq_entry.inst_info.renamed_srcL == bc_robid) begin 
                    srcL_value = bc_value[i];
                    break;
                end 
            end 
        end 
    end 
    // srcR:
    if (iq_entry.inst_info.srcR_valid) begin 
        // 通过 payload 读取
        if (iq_entry.pr_srcR_ready) begin 
            srcR_value = payload.srcR_value;
        end 
        // 通过旁路广播读取
        else if (iq_entry.bc_srcR_ready) begin 
            for (int i = 0; i < `ISSUE_WIDTH; i += 1) begin 
                if (iq_entry.inst_info.renamed_srcR == bc_robid) begin 
                    srcR_value = bc_value[i];
                    break;
                end 
            end 
        end 
    end

    // branch instruction type judge should be finished in decode stage 

    // if (inst_info_in.pred_branch == 1'b0) begin 
    //     reg_is_mispred = 1'b1;
    // end 

    // J and JAL
    if (iq_entry.inst_info.is_direct_branch) begin 
        reg_actual_addr = {iq_entry.inst_info.pc_value[31:28], iq_entry.inst_info.imm26, 2'b00};
        reg_do_jump = 1'b1;
    end 
    // BEQ, BNE, BGEZ, BLTZ, BGTZ, BLEZ, BGEZAL, BLTZAL
    else if (iq_entry.inst_info.is_cond_branch) begin 
        case (iq_entry.inst_info.comp_type)
            EQ: begin 
                if (srcL_value == srcR_value) begin 
                    reg_do_jump = 1'b1;
                    reg_actual_addr = {{14{iq_entry.inst_info.imm16[15]}}, iq_entry.inst_info.imm16, 2'b00};
                end 
                else begin 
                    reg_do_jump = 1'b0;
                    reg_actual_addr = iq_entry.inst_info.seq_pc;
                end 
            end 
            NE: begin 
                if (srcL_value != srcR_value) begin 
                    reg_do_jump = 1'b1;
                    reg_actual_addr = {{14{iq_entry.inst_info.imm16[15]}}, iq_entry.inst_info.imm16, 2'b00};
                end 
                else begin 
                    reg_do_jump = 1'b0;
                    reg_actual_addr = iq_entry.inst_info.seq_pc;
                end 
            end 
            GEZ: begin 
                if (srcL_value >= 0) begin 
                    reg_actual_addr = {{14{iq_entry.inst_info.imm16[15]}}, iq_entry.inst_info.imm16, 2'b00};
                    reg_do_jump = 1'b1;
                end
                else begin  
                    reg_actual_addr = iq_entry.inst_info.seq_pc;
                    reg_do_jump = 1'b0;
                end 
            end 
            GTZ: begin 
                if (srcL_value > 0) begin 
                    reg_actual_addr = {{14{iq_entry.inst_info.imm16[15]}}, iq_entry.inst_info.imm16, 2'b00};
                    reg_do_jump = 1'b1;
                end
                else begin 
                    reg_actual_addr = iq_entry.inst_info.seq_pc;
                    reg_do_jump = 1'b0;
                end
            end 
            LEZ: begin
                if (srcL_value <= 0) begin 
                    reg_actual_addr = {{14{iq_entry.inst_info.imm16[15]}}, iq_entry.inst_info.imm16, 2'b00};
                    reg_do_jump = 1'b1;
                end 
                else begin 
                    reg_actual_addr = iq_entry.inst_info.seq_pc;
                    reg_do_jump = 1'b0;
                end 
            end 
            LTZ: begin 
                if (srcL_value < 0) begin 
                    reg_actual_addr = {{14{iq_entry.inst_info.imm16[15]}}, iq_entry.inst_info.imm16, 2'b00};
                    reg_do_jump = 1'b1;
                end
                else begin 
                    reg_actual_addr = iq_entry.inst_info.seq_pc;
                    reg_do_jump = 1'b0;
                end 
            end  
        endcase
    end 
    // JR, JALR
    else begin 
        reg_do_jump = 1'b1;
        reg_actual_addr = srcL_value;
    end 

    // 记录延迟槽指令之后的指令的 PC 值（并广播）
    if (iq_entry.inst_info.need_log) begin 
        reg_write_back = 1'b1;
        reg_result = iq_entry.inst_info.pc_value + 8;
        reg_wb_robid = iq_entry.inst_info.rob_id;
    end 
end

assign mispred = (reg_do_jump != iq_entry.inst_info.pred_branch) || 
                (reg_actual_addr != iq_entry.inst_info.pred_addr);

endmodule