`ifndef ISSUE_PHASE_STRUCT
`define ISSUE_PHASE_STRUCT

`include "../Common/CommonConfig.svh"
`include "../RegisterRenaming/RRPhaseConfig.svh"

typedef struct {
    logic [`REG_WIDTH-1: 0] srcL_value;
    logic [`ROB_INDEX_WIDTH-1: 0] srcL_robid;
    logic srcL_valid;
    logic srcL_ready;

    logic [`REG_WIDTH-1: 0] srcR_value;
    logic [`ROB_INDEX_WIDTH-1: 0] srcR_robid;
    logic srcR_valid;
    logic srcR_ready;

    logic occurpied;
} PayloadEntry;


`endif 