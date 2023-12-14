`ifndef ID_PHASE_CONFIG
`define ID_PHASE_CONFIG


`define INST_WIDTH 32 // length of a instruction

`define MACHINE_WIDTH 8  // decode 8 instrucitons per cycle
`define SHAMT_WIDTH 5
`define IB_INDEX_WIDTH 10 // max size of instruction buffer is 1024

`define IB_SIZE 2**`IB_INDEX_WIDTH

`endif