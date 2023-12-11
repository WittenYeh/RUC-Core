`include "IFPhaseConfig.svh"

module ICache (
    input wire clk,
    input wire reset,
    input wire enread,
    input wire enwrite,
    input wire [`INST_ADDR_WIDTH-1:0] addr [`IF_GROUP_SIZE],
    output wire [`INST_ADDR_WIDTH-1:0] result [`IF_GROUP_SIZE]
);
    
reg [`INST_ADDR_WIDTH-1: 0] data [`ICACHE_CAPACITY];

reg [`INST_ADDR_WIDTH-1: 0] reg_result [`IF_GROUP_SIZE];
generate 
    for (genvar j = 0; j < `IF_GROUP_SIZE; j += 1) begin
        assign result[j] = reg_result[j];
    end
endgenerate

always_ff @(posedge clk) begin
    if (reset) begin
        // TODO: read mips asm file 
    end
    if (enwrite) begin
        // TODO: write instruction fetch (not required now)
    end
    if (enread) begin 
        // TODO: implementation port interleaving
        for (int i = 0; i < `IF_GROUP_SIZE; i += 1) begin
            reg_result[i] = data[addr[i] >> 2];
        end
    end 
end

endmodule