`include "IFPhaseConfig.svh"

module PCRegister(
    input wire reset,
    input wire enwrite,
    input wire clk,
    input wire [`INST_ADDR_WIDTH:0] next_pc,
    output wire [`INST_ADDR_WIDTH:0] result
);

reg [`INST_ADDR_WIDTH:0] cur_pc;

assign result = next_pc; // to solve read when writing: write through method

always@(posedge clk) begin
    if (reset) begin 
        cur_pc = `INST_ADDR_WIDTH 'b0;
    end
    if (enwrite) begin 
        cur_pc = next_pc;
    end
end

endmodule