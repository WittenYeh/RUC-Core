`include "IFPhaseConfig.svh" 

module TagGenerator(
    input wire [`INST_ADDR_WIDTH-1: 0] inst_addr,
    output wire [`BTB_TAG_WIDTH-1: 0] result
);

assign result = inst_addr[`BTB_TAG_WIDTH+1: 2];

endmodule 