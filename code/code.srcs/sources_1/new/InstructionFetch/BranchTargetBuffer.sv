`include "IFPhaseConfig.svh"
`include "IFPhaseStruct.svh"
`include "../Commit/CommitPhaseConfig.svh"

module BranchTargetBuffer(
    input wire clk,
    input wire reset,
    input wire enupdate [`COMMIT_WIDTH],
    input wire [`BTB_INDEX_WIDTH-1: 0] read_index [`IF_GROUP_SIZE],
    input wire [`BTB_INDEX_WIDTH-1: 0] write_index [`COMMIT_WIDTH],
    input wire [`BTB_TAG_WIDTH-1: 0] read_tag [`IF_GROUP_SIZE],
    input wire [`BTB_TAG_WIDTH-1: 0] write_tag [`COMMIT_WIDTH],
    input BranchType write_type [`COMMIT_WIDTH],
    input wire [`INST_ADDR_WIDTH-1: 0] tar_addr_in [`COMMIT_WIDTH],
    output wire [`INST_ADDR_WIDTH-1: 0] tar_addr_out [`IF_GROUP_SIZE],
    output wire valid_out [`IF_GROUP_SIZE]
);

BTBEntry entries [2**`BTB_INDEX_WIDTH];

reg [`INST_ADDR_WIDTH-1: 0] reg_tar_addr_out [`IF_GROUP_SIZE];
reg reg_valid_out [`IF_GROUP_SIZE];
generate
    for (genvar j = 0; j < `IF_GROUP_SIZE; j += 1) begin 
        assign tar_addr_out[j] = reg_tar_addr_out[j];
        assign valid_out[j] = reg_valid_out[j];
    end 
endgenerate

// update 
always_ff @(posedge clk) begin 
    // reset
    if (reset) begin 
        for (int i = 0; i < 2**`BTB_INDEX_WIDTH; ++i) begin 
            entries[i].valid <= 0;
            entries[i].tag <= `BTB_TAG_WIDTH'b0;
            entries[i].branch_type <= NORMAL_BRANCH;
            entries[i].branch_target_addr <= `INST_ADDR_WIDTH'b0;
        end 
    end
    // update
    else begin 
        for (int i = 0; i < `COMMIT_WIDTH; i += 1) begin 
            if (enupdate[i]) begin 
                entries[write_index[i]].valid <= 1'b1;
                entries[write_index[i]].branch_type <= write_type[i];
                entries[write_index[i]].tag <= write_tag[i];
                entries[write_index[i]].branch_target_addr <= tar_addr_in[i];
            end
        end
    end
end 

// read
always_comb begin
    for (int i = 0; i < `IF_GROUP_SIZE; i += 1) begin 
        // valid case
        if (entries[read_index[i]].tag == read_tag[i] && entries[read_index[i]].valid == 1'b1) begin 
            reg_valid_out[i] = 1'b1;
            reg_tar_addr_out[i] = entries[i].branch_target_addr;
        end 
        // invalid case
        else begin
            reg_valid_out[i] = 1'b0;
            reg_tar_addr_out[i] = entries[i].branch_target_addr;
        end
    end 
end


endmodule