`include "RRPhaseConfig.svh"
`include "RRPhaseStruct.svh"
`include "../InstructionDecode/IDPhaseConfig.svh"
`include "../InstructionDecode/IDPhaseStruct.svh"
`include "../Issue/IssuePhaseConfig.svh"
`include "../Commit/CommitPhaseConfig.svh"

module ReorderBuffer #(
    parameter ROB_SIZE = 2**`ROB_INDEX_WIDTH
) (
    input wire reset,
    input wire clk, 
    input wire dispatch_en,
    input wire write_en,
    input wire update_en,  // to update the state of instructions in the ROB
    input wire commit_en,
    input InstructionInfo inst_info_in [`MACHINE_WIDTH],
    input wire [`ROB_INDEX_WIDTH-1: 0] executed_bus,
    output wire fail_write,
    output InstructionInfo dispatch_inst [`ISSUE_WIDTH], // send to dispatcher
    output InstructionInfo commit_inst [`COMMIT_WIDTH] // send to commit phase
);

reg [`ROB_INDEX_WIDTH: 0] num_items;     // number of instructions in ROB
reg [`ROB_INDEX_WIDTH: 0] num_undispatched;   // number of instructions waiting to be sent to issue queue
reg [`ROB_INDEX_WIDTH: 0] num_executed;   // number of instructions that is executed

reg [`ROB_INDEX_WIDTH: 0] actual_dispatch;
reg [`ROB_INDEX_WIDTH: 0] actual_commit;

reg [`ROB_INDEX_WIDTH-1: 0] write_ptr;  
reg [`ROB_INDEX_WIDTH-1: 0] retire_ptr;
reg [`ROB_INDEX_WIDTH-1: 0] dispatch_ptr;

ROBEntry entries [ROB_SIZE];

wire [`ROB_INDEX_WIDTH-1: 0] wptrs [`MACHINE_WIDTH];
wire [`ROB_INDEX_WIDTH-1: 0] rptrs [`COMMIT_WIDTH]; 
wire [`ROB_INDEX_WIDTH-1: 0] dptrs [`DISPATCH_WIDTH];

// very good
generate
    for (genvar j = 0; j < `MACHINE_WIDTH; j += 1) begin 
        assign wptrs[j] = (write_ptr + j) % ROB_SIZE;
    end 
    for (genvar j = 0; j < `COMMIT_WIDTH; j += 1) begin 
        assign rptrs[j] = (retire_ptr + j) % ROB_SIZE;
    end 
    for (genvar j = 0; j < `DISPATCH_WIDTH; j += 1) begin 
        assign dptrs[j] = (dispatch_ptr + j) % ROB_SIZE;
    end
endgenerate

assign fail_write = (num_items+`MACHINE_WIDTH) > ROB_SIZE;

// If the instruction can find source register's renaming register in ROB but the ROB entry is not executed
// it may have one of following status:
// status 1: Not dispatched to issue queue or dispatched but not issued (by waking up and bypass)
// status 2: In issue queue but will not issue in next cycle (by payloadRAM)
// status 3: In executed phase (by payloadRAM)

MIN #(.INPUT_WIDTH(2), .INPUT_SIZE(`ROB_INDEX_WIDTH)) 
min (
    .data_in({}),
    .result(actual_issue)
);

always_ff @(posedge clk) begin
    if (reset) begin 
        num_items <= 0;
        write_ptr <= `ROB_INDEX_WIDTH'b0;
        retire_ptr <= `ROB_INDEX_WIDTH'b0;
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
        for (int i = 0; i < `MACHINE_WIDTH; i += 1) begin 
            entries[wptrs[i]].inst_info <= inst_info_in[i];
            entries[wptrs[i]].occupied <= 1'b1;
            entries[wptrs[i]].dispatched <= 1'b0;
            entries[wptrs[i]].executed <= 1'b0;
            entries[wptrs[i]].inst_info.rob_id <= entries[i].rob_id; 
        end 
        write_ptr <= (write_ptr + `MACHINE_WIDTH) % ROB_SIZE;
    end 
    // enable dispatch
    if (dispatch_en) begin 
        
    end  
    // enable update
    if (update_en) begin 

    end
    // enable commit
    if (commit_en) begin 

    end 
end

endmodule

