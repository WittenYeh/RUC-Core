`include "RRPhaseConfig.svh"
`include "RRPhaseStruct.svh"
`include "../InstructionDecode/IDPhaseConfig.svh"
`include "../InstructionDecode/IDPhaseStruct.svh"

module ReorderBuffer #(
    parameter ROB_SIZE = 2**`ROB_INDEX_WIDTH
) (
    input wire inst_valid [`MACHINE_WIDTH],
    input InstructionInfo inst_info [`MACHINE_WIDTH],
    output wire is_full,
    output wire is_empty
);
    
endmodule

