`include "IF_PHASE_CONFIG.vh"

module PCRegister(
    input wire reset,
    input wire enwrite,
    input wire clk,
    input wire [`INST_ADDR_WIDTH:0] next_pc,
    output wire [`INST_ADDR_WIDTH:0] result
);

reg [`INST_ADDR_WIDTH:0] cur_pc;

assign result = cur_pc;

always@(posedge clk) begin
    if (reset) begin 
        cur_pc = `INST_ADDR_WIDTH 'b0;
    end
    if (enwrite) begin 
        cur_pc = next_pc;
    end
end

endmodule