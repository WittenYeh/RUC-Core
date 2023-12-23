`include "IFPhaseConfig.svh"
`include "IFPhaseStruct.svh"
`include "../Commit/CommitPhaseConfig.svh"

module ReturnAddressStack(
    input wire clk,
    input wire reset,
    input wire [`INST_ADDR_WIDTH-1: 0] inst_addr [`COMMIT_WIDTH],
    output wire [`INST_ADDR_WIDTH-1: 0] return_addr
);


endmodule