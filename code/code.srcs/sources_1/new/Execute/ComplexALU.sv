`include "../InstructionDecode/IDPhaseStruct.svh"
`include "../InstructionFetch/IFPhaseConfig.svh"
`include "../RegisterRenaming/RRPhaseConfig.svh"
`include "../Issue/IssuePhaseStruct.svh"
`include "../Issue/IssuePhaseConfig.svh"


/*
 * ComplexALU 仅负责计算，不负责将结果转发到广播总线上
 * Move 指令同时在这里实现，用于将 HI 寄存器和 LO 寄存器的值移动到目的寄存器中
 * 
 * 每个乘法指令都会产生一对 HI 和 LO
 * 因此需要解决 MOVE 指令和 HI 和 LO 的对应关系
 * 可以在重排序缓存中指定 ComplexALU 的编号
 * 在广播的过程中，MOVE 指令还需要往前寻找到最近的一条乘法指令
 * 然后获取这条乘法指令当前结果所在的 ComplexALU 编号
 * 
 * 将 MOVE 指令分派到这个编号对应的 ComplexALU
 * MOVE 指令执行的周期会占用这个 ComplexALU
 * 当下一条乘法指令到来时，意味着 ComplexALU 的 HI 和 LO 寄存器需要被更新
 * 鉴于每次 MOVE 指令都能寻到距离最近的 ComplexALU
 * 因此这个方法能实现乘法指令的乱序执行
 */
module ComplexALU #(
    
) (
    input IQEntry iq_entry,
    input PayloadEntry payload,
    input wire [`ROB_INDEX_WIDTH-1: 0] bc_robid,
    input wire [`REG_WIDTH-1: 0] bc_value [`ISSUE_WIDTH],
    output wire write_back, // 该单元计算得到的结果是否需要写回
    output wire [`REG_WIDTH-1: 0] result [2],  // 计算结果
    // complex robid 需要广播两个编号
    output wire [`ROB_INDEX_WIDTH-1: 0] wb_robid [2] // 需要写到哪个 robid (同时将放到广播通路上)
);

assign write_back = 1'b1; // 该单元计算出的结果必定需要写回
assign wb_robid [0] = iq_entry.inst_info.rob_id;

reg [`REG_WIDTH-1: 0] reg_result [2];
assign result[0] = reg_result[0];
assign result[1] = reg_result[1];

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
                    break;
                end 
            end 
        end 
    end

    if (iq_entry.inst_info.calu_op == ALU_DIV) begin 
        // TODO: 使用子模块实现
        // reg_result = srcL_value / srcR_value;
    end
    else if (iq_entry.inst_info.calu_op == ALU_MUL) begin 
        // reg_result = srcL_value * srcR_value;
    end 
        // TODO: 修改 ROB 缓存项中的内容，使得同时支持 LO 和 HI 的处理 
    // 给 HI 和 LO 分别设置一个编号
    // 数据移动指令
    else if (iq_entry.inst_info.op_type == MOVE) begin 
        case(iq_entry.inst_info.move_type) 
            HI2REG: begin 
                
            end 
            REG2HI: begin 
            end 
            LO2REG: begin 
            end
            REG2LO: begin 
            end
        endcase 
    end 
    else begin 
        // TODO: 报错：不应该运行到此处
    end 
end 

endmodule