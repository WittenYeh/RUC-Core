`include "IFPhaseConfig.svh"
`include "IFPhaseStruct.svh"

module Predictor(
    input wire [`INST_ADDR_WIDTH-1: 0] cur_pc,
    input wire [`INST_ADDR_WIDTH-1: 0] mispred_pc [`IF_GROUP_SIZE],
    output wire [`INST_ADDR_WIDTH-1: 0] last_pc_out, // used to update predictor state
    output wire [`INST_ADDR_WIDTH-1: 0] next_pc // predict value
);


endmodule