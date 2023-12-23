`include "IFPhaseConfig.svh"
`include "../Commit/CommitPhaseConfig.svh"

module IndirectTartgetCache(
    input wire clk, 
    input wire reset,
    input wire enupdate [`COMMIT_WIDTH],
    input wire [`ITC_INDEX_WIDTH-1: 0] read_index [`IF_GROUP_SIZE],
    input wire [`ITC_INDEX_WIDTH-1: 0] write_index [`COMMIT_WIDTH], 
    input wire [`INST_ADDR_WIDTH-1: 0] addr_in [`COMMIT_WIDTH],
    output wire [`INST_ADDR_WIDTH-1: 0] addr_out [`IF_GROUP_SIZE]
);

reg [`INST_ADDR_WIDTH-1: 0] indirect_target [2**`ITC_INDEX_WIDTH];

reg [`INST_ADDR_WIDTH-1: 0] reg_addr_out [`IF_GROUP_SIZE];
generate
    for (genvar j = 0; j < `IF_GROUP_SIZE; j += 1) begin 
        assign addr_out[j] = reg_addr_out[j];
    end
endgenerate



// update 
always_ff @(posedge clk) begin
    if (reset) begin 
        for (int i = 0; i < 2**`ITC_INDEX_WIDTH; i += 1) begin 
            indirect_target[i] <= `INST_ADDR_WIDTH'b0;
        end 
    end 
    else begin 
        for (int i = 0; i < `COMMIT_WIDTH; i += 1) begin 
            if (enupdate[i]) begin 
                indirect_target[write_index[i]] <= addr_in[i];
            end
        end
    end 
end


// read
always_comb begin 
    for (int i = 0; i < `IF_GROUP_SIZE; i += 1) begin 
        reg_addr_out[read_index[i]] = indirect_target[read_index[i]];
    end 
end 

endmodule