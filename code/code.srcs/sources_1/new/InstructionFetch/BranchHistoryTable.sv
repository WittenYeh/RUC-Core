`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/03 20:43:59
// Design Name: 
// Module Name: BranchHistoryTable
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "IFPhaseConfig.svh"
`include "../Commit/CommitPhaseConfig.svh"

/*
 * in- Branch History Table:
 * in- is_branch: whether the hash_pc value causes branch or not (speculate)
 * in- hash_pc: hashed pc value, index the entry of table
 * out- pattern: the branch history pattern of hash_pc 
 */

module BranchHistoryTable(
    input wire reset,
    input wire clk,
    input wire enupdate, // all commited instructions update at the same time 
    input wire isbranch [`IF_GROUP_SIZE],
    input wire [`BHT_INDEX_WIDTH-1: 0] read_index [`IF_GROUP_SIZE],
    input wire [`BHT_INDEX_WIDTH-1: 0] write_index [`COMMIT_WIDTH],
    output wire [`PATTERN_WIDTH-1:0] pattern [`IF_GROUP_SIZE]
);

reg [`PATTERN_WIDTH-1:0] patterns_table [2**`BHT_INDEX_WIDTH];
reg [`PATTERN_WIDTH-1:0] reg_pattern [`IF_GROUP_SIZE];

generate
    for (genvar j = 0; j < `IF_GROUP_SIZE; j += 1) begin 
        assign pattern[j] = reg_pattern[j];
    end
endgenerate

always_ff @(negedge clk) begin
    if (reset) begin 
        for (int i = 0; i < 2**`BHT_INDEX_WIDTH; i+=1) begin
            patterns_table[i] <= `PATTERN_WIDTH'b0;
        end
    end
    else if (enupdate) begin
        for (int i = 0; i < `COMMIT_WIDTH; i += 1) begin 
            patterns_table[write_index[i]][`PATTERN_WIDTH-2: 0] <= patterns_table[write_index[i]][`PATTERN_WIDTH-2:0];
            patterns_table[write_index[i]][`PATTERN_WIDTH-1] <= isbranch[i];
        end
    end
end

always_comb begin
    for (int i  = 0; i < `IF_GROUP_SIZE; i += 1) begin 
        reg_pattern[i] = patterns_table[read_index[i]];
    end
end

endmodule
