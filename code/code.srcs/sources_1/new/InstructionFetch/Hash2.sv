`include "IFPhaseConfig.svh"

module Hash2(
    input wire [`INST_ADDR_WIDTH-1: 0] pc,
    input wire [`PATTERN_WIDTH-1: 0] pattern, 
    output wire [`PHT_INDEX_WIDTH-1: 0] result
);

assign result = pc[11:2] ^ pattern;

endmodule