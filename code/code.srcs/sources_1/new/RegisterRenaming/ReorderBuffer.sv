`include "RRPhaseConfig.svh"
`include "RRPhaseStruct.svh"
`include "../InstructionDecode/IDPhaseConfig.svh"
`include "../InstructionDecode/IDPhaseStruct.svh"
`include "../Issue/IssuePhaseConfig.svh"
`include "../Commit/CommitPhaseConfig.svh"
`include "../Issue/PayloadRAM.sv"

module ReorderBuffer #(
    parameter ROB_SIZE = 2**`ROB_INDEX_WIDTH
) (
    input wire reset,
    input wire clk, 
    input wire dispatch_en,
    input wire write_en,
    input wire update_en,  // to update the state of instructions in the ROB(executed or not)
    input wire commit_en,

    // 指令编排顺序：下标越小代表在程序中原始顺序越早执行
    input InstructionInfo inst_info_in [`MACHINE_WIDTH],
    input wire [`ROB_INDEX_WIDTH-1: 0] executed_bus_addr [`ISSUE_WIDTH],
    input wire [`ROB_INDEX_WIDTH-1: 0] executed_bus_value [`ISSUE_WIDTH],
    input wire executed_bus_valid [`ISSUE_WIDTH],
    
    // monitor wire
    output wire fail_write,
    output wire fail_dispatch,
    output wire fail_commit,

    output InstructionInfo dispatch_inst [`DISPATCH_WIDTH], // send to dispatcher
    output InstructionInfo commit_inst [`COMMIT_WIDTH], // send to commit phase
    output wire [`ROB_INDEX_WIDTH-1: 0] payload_addr [`MACHINE_WIDTH],
    output PayloadEntry payload_entry [`MACHINE_WIDTH] // send to payload RAM
);

ROBEntry entries [ROB_SIZE];

reg [`ROB_INDEX_WIDTH: 0] num_items;     // number of instructions in ROB
reg [`ROB_INDEX_WIDTH: 0] num_undispatched;   // number of instructions waiting to be sent to issue queue
reg [`ROB_INDEX_WIDTH: 0] num_executed;   // number of instructions that is executed

// reg [`ROB_INDEX_WIDTH: 0] actual_dispatch;
// reg [`ROB_INDEX_WIDTH: 0] actual_commit;

reg [`ROB_INDEX_WIDTH-1: 0] write_ptr;  
reg [`ROB_INDEX_WIDTH-1: 0] commit_ptr;
reg [`ROB_INDEX_WIDTH-1: 0] dispatch_ptr;

// pointers (to satisfied multi-port)
wire [`ROB_INDEX_WIDTH-1: 0] wptrs [`MACHINE_WIDTH];
wire [`ROB_INDEX_WIDTH-1: 0] cptrs [`COMMIT_WIDTH]; 
wire [`ROB_INDEX_WIDTH-1: 0] dptrs [`DISPATCH_WIDTH];

generate
    for (genvar j = 0; j < `MACHINE_WIDTH; j += 1) begin 
        assign wptrs[j] = (write_ptr + j) % ROB_SIZE;
        assign payload_addr[j] = (write_ptr + j) % ROB_SIZE;
    end 
    for (genvar j = 0; j < `COMMIT_WIDTH; j += 1) begin 
        assign cptrs[j] = (commit_ptr + j) % ROB_SIZE;
    end 
    for (genvar j = 0; j < `DISPATCH_WIDTH; j += 1) begin 
        assign dptrs[j] = (dispatch_ptr + j) % ROB_SIZE;
    end
endgenerate

// If the instruction can find source register's renaming register in ROB but the ROB entry is not executed
// it may have one of following status:
// status 1: Not dispatched to issue queue or dispatched but not issued (by waking up and bypass)
// status 2: In issue queue but will not issue in next cycle (by payloadRAM)
// status 3: In executed phase (by payloadRAM)

/* 
 * 寄存器重命名逻辑单元：实现基于 ROB 的寄存器重命名
 * 需要考虑两种情况：
 * case 1: 源寄存器对应的源指令在该周期前已经存储到 ROB 中
    * 从 ROB 的所有已写单元接收目标地址广播
    * 选择最近的源指令
 * case 2: 源寄存器对应的源指令在该周期完成 ROB 写入
    * 从同周期且早于自身的指令接收目标地址广播
    * 选择最近的源指令
 * 如果 case 1 和 case 2 都能找到源指令，那就优先选择 case 2 中源指令，因为 case 2 到来的时间比 case 1 晚
 */
// TODO: 检测一下这个寄存器重命名单元能不能用

reg [`ROB_INDEX_WIDTH-1: 0] renamed_srcL [`MACHINE_WIDTH];
reg [`ROB_INDEX_WIDTH-1: 0] renamed_srcR [`MACHINE_WIDTH];

// not sure can be simulated or not
always_comb begin 
    for (int i = 0; i < `MACHINE_WIDTH; i += 1) begin 
        // broadcast to all entries
        
        // discuss the entries before current cycle 
        for (int j = commit_ptr; j != write_ptr; j=(j+1)%ROB_SIZE) begin 
            if (entries[j].inst_info.dest_valid) begin 
                if ( entries[j].inst_info.dest==inst_info_in[i].srcL &&
                    inst_info_in[i].srcL_valid
                ) begin 
                    renamed_srcL[i] = entries[j].rob_id;
                end 
                if ( entries[j].inst_info.dest==inst_info_in[i].srcR &&
                    inst_info_in[i].srcR_valid
                ) begin 
                    renamed_srcR[i] = entries[j].rob_id;
                end 
            end    
        end     
        
        // discuss the entries in current cycle
        for (int j = 0; j < i; j += 1) begin 
            // the bigger j, the newer instruction
            if (inst_info_in[j].dest_valid) begin 
                if ( inst_info_in[j].dest==inst_info_in[i].srcL &&
                    inst_info_in[i].srcL_valid
                ) begin 
                    renamed_srcL[i] = wptrs[j];
                end 
                if ( inst_info_in[j].dest==inst_info_in[i].srcR &&
                    inst_info_in[i].srcR_valid
                ) begin 
                    renamed_srcR[i] = wptrs[j];
                end
            end  
        end 
    end
end 

always_ff @(posedge clk) begin
    if (reset) begin 
        num_items <= 0;
        write_ptr <= `ROB_INDEX_WIDTH'b0;
        commit_ptr <= `ROB_INDEX_WIDTH'b0;
        dispatch_ptr <= `ROB_INDEX_WIDTH'b0;
        for (int i = 0; i < ROB_SIZE; i += 1) begin 
            entries[i].dispatched <= 1'b0;
            entries[i].occupied <= 1'b0;
            entries[i].executed <= 1'b0;
            entries[i].rob_id <= i;
        end      
    end 
    // enable to write
    // append new instruction information
    if (write_en) begin 
        // write to ROB entries
        for (int i = 0; i < `MACHINE_WIDTH; i += 1) begin 
            entries[wptrs[i]].inst_info <= inst_info_in[i];
            entries[wptrs[i]].occupied <= 1'b1;
            entries[wptrs[i]].dispatched <= 1'b0;
            entries[wptrs[i]].executed <= 1'b0;
            entries[wptrs[i]].inst_info.rob_id <= entries[i].rob_id; 
            entries[wptrs[i]].inst_info.renamed_srcL = renamed_srcL[i];
            entries[wptrs[i]].inst_info.renamed_srcR = renamed_srcR[i];
        end 
        
        write_ptr <= (write_ptr + `MACHINE_WIDTH) % ROB_SIZE;
        
        // write to payload (stabilize in-port in first half cycle)
        for (int i = 0; i < `MACHINE_WIDTH; i += 1) begin 
            // discuss left source
            // write value 
            if ( inst_info_in[i].srcL_valid &&
                entries[renamed_srcL[i]].occupied && 
                entries[renamed_srcL[i]].executed
            ) begin 
                payload_entry[i].srcL_value <= entries[renamed_srcL[i]].rd_value;
                payload_entry[i].srcL_ready <= 1'b1;
            end 
            // write ROB id
            else if (inst_info_in[i].srcL_valid) begin 
                payload_entry[i].srcL_robid <= entries[renamed_srcL[i]].rob_id;
                payload_entry[i].srcL_ready <= 1'b0;
            end 

            // discuss right source
            // write value
            if ( inst_info_in[i].srcR_valid &&
                entries[renamed_srcR[i]].occupied && 
                entries[renamed_srcR[i]].executed
            ) begin 
                payload_entry[i].srcR_value <= entries[renamed_srcR[i]].rd_value;
                payload_entry[i].srcR_ready <= 1'b1;
            end
            // write ROB id
            else if (inst_info_in[i].srcR_valid) begin 
                payload_entry[i].srcL_robid <= entries[renamed_srcR[i]].rob_id;
                payload_entry[i].srcR_ready <= 1'b0;
            end 
        end
    end 
    // enable dispatch
    if (dispatch_en) begin 
        for (int i = 0; i < `DISPATCH_WIDTH; i += 1) begin
            dispatch_inst[i] = entries[dptrs[i]].inst_info;
            entries[dptrs[i]].dispatched <= 1'b1;
        end
        dispatch_ptr <= (dispatch_ptr + `MACHINE_WIDTH) % ROB_SIZE;
    end  
    // enable update
    if (update_en) begin 
        for (int i = 0; i < `ISSUE_WIDTH; i += 1) begin 
            if (executed_bus_valid[i]) begin 
                entries[executed_bus_addr[i]].executed = 1'b1;
                // rd_value wiil always be set, in no rd_value case, it's nothing, because its rd_value will be never used
                entries[executed_bus_addr[i]].rd_value = executed_bus_value[i];
            end 
        end 
    end
    // enable commit
    if (commit_en) begin 
        for (int i = 0; i < `COMMIT_WIDTH; i += 1) begin 
            commit_inst[i] = entries[cptrs[i]].inst_info;
            entries[cptrs[i]].occupied <= 1'b0; // say goodbye to the instruction
        end 
        commit_ptr <= (commit_ptr + `COMMIT_WIDTH) % ROB_SIZE;
    end 
end

assign fail_write = (num_items+`MACHINE_WIDTH) > ROB_SIZE;
assign fail_dispatch = num_undispatched < `DISPATCH_WIDTH;
assign fail_commit = num_executed < `COMMIT_WIDTH;

endmodule

