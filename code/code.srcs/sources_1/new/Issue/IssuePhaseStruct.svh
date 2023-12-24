`ifndef ISSUE_PHASE_STRUCT
`define ISSUE_PHASE_STRUCT

`include "../Common/CommonConfig.svh"
`include "../RegisterRenaming/RRPhaseConfig.svh"

typedef struct {
    logic [`REG_WIDTH-1: 0] srcL_value;
    logic [`ROB_INDEX_WIDTH-1: 0] srcL_robid;   // renamed ROB id
    // logic srcL_valid;
    logic srcL_ready;

    logic [`REG_WIDTH-1: 0] srcR_value;
    logic [`ROB_INDEX_WIDTH-1: 0] srcR_robid;   // renamed ROB id
    // logic srcR_valid;
    logic srcR_ready;

    logic occurpied;
} PayloadEntry;

typedef struct {
    logic [`ROB_INDEX_WIDTH-1: 0] rd_robid; // 
    /* 
     * invalid cases:
     * some instructions do not have rd field
     * sometimes issue output ports are not fully used, only part of them are sensitive 
     */
    logic valid;                            // whether this broadcast valid
} IssueBroadcast;

typedef struct {
    InstructionInfo inst_info;  
    // some instruction may wake-up but not issue
    
    // logic wake_up; 
    
    // TODO: varible to implement logic about delayed wake up
    // balabala...
    
    // ready signal from broadcast
    logic bc_srcL_ready;
    logic bc_srcR_ready;
    // ready signal from payloadRAM
    logic pr_srcL_ready;
    logic pr_srcR_ready;
} IQEntry;

`endif 