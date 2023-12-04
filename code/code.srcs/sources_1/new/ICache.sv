`include "IFPhaseConfig.vh"

module ICache (
    input wire clk,
    input wire reset,
    input wire enread,
    input wire enwrite,
    input wire [`INST_ADDR_WIDTH-1:0] addr,
    output wire [`INST_ADDR_WIDTH-1:0] result [`IF_WIDTH-1 : 0]
);
    
reg [`INST_ADDR_WIDTH-1: 0] data [`ICACHE_CAPACITY: 0];

reg [`INST_ADDR_WIDTH-1: 0] tmp_result [`IF_WIDTH-1: 0];
integer linenum;

generate 
    for (genvar j = 0; j < `IF_WIDTH; j += 1) begin
        assign result[j] = tmp_result[j];
    end
endgenerate

always @(posedge clk) begin
    if (reset) begin
        // TODO: read mips asm file 
    end
    if (enwrite) begin
        // TODO: write instruction fetch (not required now)
    end
    if (enread) begin 
        // TODO: implementation port interleaving
        for (int i = 0; i < `IF_WIDTH; i += 1) begin
            tmp_result[i] = data[addr + i];
        end
    end 
end

endmodule