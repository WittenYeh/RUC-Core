`ifndef RR_PHASE_STRUCT
`define RR_PHASE_STRUCT

`include "RRPhaseConfig.svh"
`include "../InstructionDecode/IDPhaseStruct.svh"

typedef struct {
    InstructionInfo inst_info;
    logic [31:0] target_data;
} ROBEntry;

// don't need to define Renaming Address Table
// no RAT renaming
// use a broadcast way



`endif
