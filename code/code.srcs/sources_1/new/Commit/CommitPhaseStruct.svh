`ifndef CommitPhaseStruct
`define CommitPhaseStruct

`include "../Commit/CommitPhaseConfig.svh"
`incude "../Common/CommonConfig.svh"

typedef struct {
    logic [`REG_WIDTH-1: 0] result;
} CommitEntry;

`endif 