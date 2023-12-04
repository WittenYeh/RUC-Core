`include "IFPhaseConfig.vh"

module Hash1(
    input wire[`INST_ADDR_WIDTH-1: 0] pc,
    input wire[`BHT_PC_HASH_WIDTH-1: 0] result
);

assign result = pc[`BHT_PC_HASH_WIDTH-1: 0];

endmodule