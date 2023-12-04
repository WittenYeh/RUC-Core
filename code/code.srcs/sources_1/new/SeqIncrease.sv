`include "IF_PHASE_CONFIG.vh"

module SeqIncrease(
    input wire [31:0] prev_pc,
    output wire [31:0] result
);

assign result = prev_pc + 4 *(`IF_WIDTH);

endmodule