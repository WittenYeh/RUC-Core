`include "IFPhaseConfig.svh"

module Hash1(
    input wire[`INST_ADDR_WIDTH-1: 0] pc,
    output wire[`BHT_INDEX_WIDTH+1: 2] result
);

assign result = pc[`BHT_INDEX_WIDTH+1: 2];

endmodule