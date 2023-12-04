`ifndef IF_PHASE_STRUCT
`define IF_PHASE_STRUCT

`include "IFPhaseConfig.vh"

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

`endif