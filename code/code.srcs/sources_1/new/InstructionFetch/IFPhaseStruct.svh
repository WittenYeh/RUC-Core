`ifndef IF_PHASE_STRUCT
`define IF_PHASE_STRUCT

`include "IFPhaseConfig.svh"

typedef struct {            
    logic valid;
    logic [`BTB_TAG_WIDTH-1 : 0] tag;
    logic [`INST_ADDR_WIDTH-1 : 0] branch_target_addr;
    logic [`BTB_TYPE_WIDTH-1 : 0] branch_type;
} BTBEntry;

typedef enum logic[`BTB_TYPE_WIDTH-1 : 0] {
    RETURN_BRANCH,
    CALL_BRANCH,
    NORMAL_BRANCH,
    INDIRECT_BRANCH
} BranchType;

// use grey code to reduce power comsumption
typedef enum logic[`BIMODAL_COUNTER_WIDTH-1: 0] {
    STRONGLY_NOT_TAKEN = 2'b00,
    WEALY_NOT_TAKEN = 2'b01,
    WEAKLY_TAKEN = 2'b11,
    STRONGLY_TAKEN = 2'b10
} ImodalCounterState;

`endif