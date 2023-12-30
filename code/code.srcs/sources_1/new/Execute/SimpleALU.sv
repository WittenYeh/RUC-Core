`include "../InstructionDecode/IDPhaseStruct.svh"
`include "../InstructionFetch/IFPhaseConfig.svh"
`include "../RegisterRenaming/RRPhaseConfig.svh"
`include "../Issue/IssuePhaseStruct.svh"
`include "../Issue/IssuePhaseConfig.svh"

// SimpleALU 指令用于实现 
module SimpleALU #(
    
) (
    input IQEntry iq_entry,
    input PayloadEntry payload,
    input wire [`ROB_INDEX_WIDTH-1: 0] bc_robid,
    input wire [`REG_WIDTH-1: 0] bc_value [`ISSUE_WIDTH],
    // output wire write_back, // 该单元计算得到的结果是否需要写回
    output wire [`REG_WIDTH-1: 0] result,  // 计算结果
    output wire [`ROB_INDEX_WIDTH-1: 0] wb_robid // 需要写到哪个 robid (同时将放到广播通路上)
);

// assign write_back = 1'b1; // 该单元计算出的结果必定需要写回
assign wb_robid = iq_entry.inst_info.rob_id;

reg [`REG_WIDTH-1: 0] reg_result;
assign result = reg_result;

reg [`REG_WIDTH-1: 0] srcL_value;
reg [`REG_WIDTH-1: 0] srcR_value;

always_comb begin 
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
                    break;  // 只要读取到对应的广播值就可以中断
                end 
            end 
        end 
    end

    // 位移指令
    if (iq_entry.inst_info.op_type == SHIFT) begin 
        case(iq_entry.inst_info.shift_type) 
            LEFT: begin
                // SLL
                if (iq_entry.inst_info.shamt_valid) begin 
                    // 由立即数 sa 指定移位量，对寄存器 rt 的值进行逻辑左移，结果写入寄存器 rd 中。
                    reg_result = srcR_value << iq_entry.inst_info.shamt;
                end   
                // SLLV
                else begin 
                    // 由寄存器 rs 中的值指定移位量，对寄存器 rt 的值进行算术右移，结果写入寄存器 rd 中。
                    reg_result = srcR_value << iq_entry.inst_info.srcL_value;
                end 
            end  
            A_RIGHT: begin 
                // SRA
                if (iq_entry.inst_info.shamt_valid) begin
                    reg_result = ($signed(srcR_value)) >>> iq_entry.inst_info.shamt;
                end 
                // SRAV
                else begin 
                    reg_result = ($signed(srcR_value)) >>> iq_entry.inst_info.srcL_value;
                end 
            end 
            L_RIGHT: begin 
                // SRL
                if (iq_entry.inst_info.shamt_valid) begin
                    reg_result = srcR_value >> iq_entry.inst_info.shamt;
                end 
                // SRLV
                else begin 
                    reg_result = srcR_value >> iq_entry.inst_info.srcL_value;
                end
            end 
            default: begin 
                // TODO: 报错
            end 
        endcase
    end  
    // 简单四则运算指令
    else if (iq_entry.inst_info.op_type == SIMPLE_ALU) begin 
        case (iq_entry.inst_info.salu_op) 
            ALU_ADD: begin
                reg_result = srcL_value + srcR_value;
            end 
            ALU_AND: begin 
                reg_result = srcL_value & srcR_value;
            end 
            ALU_NOR: begin 
                reg_result = ~(srcL_value | srcR_value);
            end
            ALU_OR: begin 
                reg_result = srcL_value | srcR_value;
            end 
            ALU_SUB: begin 
                reg_result = srcL_value - srcR_value;
            end 
            ALU_XOR: begin 
                reg_result = srcL_value ^ srcR_value;
            end 
            default: begin 
                // TODO: 报错
            end 
        endcase
    end 
end 

endmodule