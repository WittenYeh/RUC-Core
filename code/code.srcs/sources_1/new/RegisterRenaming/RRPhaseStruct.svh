`ifndef RR_PHASE_STRUCT
`define RR_PHASE_STRUCT

`include "RRPhaseConfig.svh"
`include "../InstructionDecode/IDPhaseStruct.svh"

typedef struct {
    InstructionInfo inst_info;
    logic [31:0] rd_value;
    logic [`ROB_INDEX_WIDTH-1: 0] rob_id;
    logic dispatched;
    logic occupied;
    logic executed;
} ROBEntry;

// don't need to define Renaming Address Table
// no RAT renaming
// use a broadcast method to implement register renaming instead



`endif
