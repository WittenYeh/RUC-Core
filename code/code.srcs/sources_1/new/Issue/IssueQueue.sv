`include "../InstructionDecode/IDPhaseStruct.svh"
`include "../RegisterRenaming/RRPhaseConfig.svh"
`include "./IssuePhaseStruct.svh"
`include "./IssuePhaseConfig.svh"

/*
 * 四种不同的发射队列应该采用不同的结构，因为乱序执行的程度不一样
 * SimpleALU 指令对应的发射队列采用完全乱序执行
 * Branch 指令对应的发射队列采用顺序执行
    * 因为分支预测错误会导致后面所有的指令都处于错误路径上
    * 顺序执行是比较保守的规避错误的方式
 * Memory 指令对应的发射队列采用部分乱序执行
    * 所有 store 指令都必须顺序执行来确保存储器的正确性
    * 两条 store 指令之间的 load 指令可以乱序执行
    * store 指令必须写到内存才能被 load 指令读取
    * 因此在周期 T，一条 store 指令执行以后
    * 在 T+1 周期，程序中原始顺序这这条 store 指令后的所有 load 指令都可以被执行
 * ComplexALU 指令对应的发射队列采用完全乱序执行
    * 乘法指令可以分配到两个 ALU 上并行执行
    * MOVE 指令分配到对应 ComplexALU 上执行
 */

// Cluster Framework
module IssueQueue #(
    parameter OUTPUT_WIDTH = 2,
    parameter IQ_SIZE = 2**`IQ_INDEX_WIDTH 
) (
    // the worst case: should support `DISPATCH_WIDTH port
    input wire clock,
    input wire reset,
    input wire [`DISPATCH_WIDTH: 0] actual_write,
    input InstructionInfo inst_info_in [`DISPATCH_WIDTH],
    input wire write_en,
    input wire issue_en,
    input wire wakeup_en, // 更新唤醒状态
    input wire pr_srcL_ready [2**`ROB_INDEX_WIDTH],
    input wire pr_srcR_ready [2**`ROB_INDEX_WIDTH],
    input IssueBroadcast broadcast_in [`ISSUE_WIDTH],
    output IQEntry entry_out [OUTPUT_WIDTH],
    output reg valid_out [OUTPUT_WIDTH],
    output IssueBroadcast broadcast_out [OUTPUT_WIDTH],
    output wire fail_issue
);

reg [`IQ_INDEX_WIDTH: 0] num_items;     // num_items is write ptr here

// the instruction that are write 
reg [`IQ_INDEX_WIDTH: 0] actual_issue;
reg [`IQ_INDEX_WIDTH-1: 0] issue_pos [OUTPUT_WIDTH];

IQEntry entries [IQ_SIZE];
reg [`IQ_INDEX_WIDTH-1: 0] updated_entries_pos [IQ_SIZE];

wire wake_up [IQ_SIZE];

generate
    for (genvar i = 0; i < IQ_SIZE; i += 1) begin 
        WakeupUnit wakeup_unit(
            .iq_entry(entries[i]),
            .wake_up(wake_up[i])
        );
    end
endgenerate

// logic to compute actual_issue
// TODO: check whether this logic can be executed 
always_comb begin 
    actual_issue = 0;
    
    // find issue position logic
    for (int i = 0; i < num_items; i += 1) begin 
        if (actual_issue == OUTPUT_WIDTH) begin 
            break;
        end 
        if (wake_up[i]) begin 
            issue_pos[actual_issue] = i;
            actual_issue += 1;
        end
    end 
    
    // find updated position after some instruction has been issued
    for (int i = 0; i < num_items; i += 1) begin
        updated_entries_pos[i] = i;
        for (int j = 0; j < actual_issue; j += 1) begin 
            // if i is one of issue position, do nothing
            if (i == issue_pos[j]) begin 
                updated_entries_pos[i] = i;  // the instruction in this position will be issued, just let other instruction to pad it
            end 
            else if (i > issue_pos[j]) begin 
                updated_entries_pos[i] -= 1;
            end 
        end 
    end
end 

// first half cycle issue, 
// second half cycle padding

// issue logic
always_ff @(posedge clock) begin
    if (reset) begin 
        for (int i = 0; i < IQ_SIZE; i += 1) begin 
            num_items <= 0;
            entries[i].bc_srcL_ready = 1'b0;
            entries[i].bc_srcR_ready = 1'b0;
            entries[i].pr_srcL_ready = 1'b0;
            entries[i].pr_srcR_ready = 1'b0;
        end 
    end 
    
    if (issue_en) begin 
        // assign instructions to output broadcast port
        for (int i = 0; i < OUTPUT_WIDTH; i += 1) begin 
            if (i < actual_issue) begin 
                entry_out[i] <= entries[issue_pos[i]];
                valid_out[i] <= 1'b1;
                if (entries[issue_pos[i]].inst_info.dest_valid) begin 
                    broadcast_out[i].valid <= 1'b1;
                    broadcast_out[i].rd_robid <= entries[issue_pos[i]].inst_info.rob_id;
                end
                else begin 
                    broadcast_out[i].valid <= 1'b0;
                end 
            end
            else begin
                valid_out[i] <= 1'b0;
                broadcast_out[i].valid <= 1'b0;
            end
        end 
        // compress issue queue
        for (int i = 0; i < num_items; i += 1) begin 
            entries[i] <= entries[updated_entries_pos[i]];
        end 
    end 

    if (write_en) begin 
        // this operation will automatically
        for (int i = 0; i < actual_write; i += 1) begin 
            entries[num_items-actual_issue+i].inst_info <= inst_info_in[i];
            entries[i].bc_srcL_ready = 1'b0;
            entries[i].bc_srcR_ready = 1'b0;
            entries[i].pr_srcL_ready = 1'b0;
            entries[i].pr_srcR_ready = 1'b0;
        end 
    end 
    
    // after issueing and writing, update number of items
    num_items <= num_items + write_en*actual_write - issue_en*actual_issue;
end

// bc_srcL_ready 和 pr_srcL_ready 不可能同时为 1，对于 srcR 同理

// wake up logic
always_ff @(negedge clock) begin
    // wake up by wakeup broadcast
    if (wakeup_en) begin 
        for (int i = 0; i < `ISSUE_WIDTH; i += 1) begin
            for (int j = 0; j < num_items; j += 1) begin 
                if (broadcast_in[i].valid) begin 
                    if (entries[j].inst_info.renamed_srcL == broadcast_in[i].rd_robid) begin 
                        entries[j].bc_srcL_ready <= 1'b1;  
                    end 
                    if (entries[j].inst_info.renamed_srcR == broadcast_in[i].rd_robid) begin 
                        entries[j].bc_srcR_ready <= 1'b1;
                    end
                end 
            end 
        end 
        // wake up by payload ready signal
        for (int i = 0; i < 2**`ROB_INDEX_WIDTH; i += 1) begin 
            entries[i].pr_srcL_ready = pr_srcL_ready[i];
            entries[i].pr_srcR_ready = pr_srcR_ready[i];
        end 
    end 
end

assign fail_issue = (num_items == 0);

endmodule