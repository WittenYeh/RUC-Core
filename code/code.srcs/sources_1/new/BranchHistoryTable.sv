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

`include "IFPhaseConfig.vh"

/*
 * in- Branch History Table:
 * in- is_branch: whether the hash_pc value causes branch or not (speculate)
 * in- hash_pc: hashed pc value, index the entry of table
 * out- pattern: the branch history pattern of hash_pc 
 */

module BranchHistoryTable(
        input wire reset,
        input wire clk,
        input wire enupdate,
        input wire is_branch,
        input wire [`BHT_PC_HASH_WIDTH-1: 0] hash_pc,
        output wire [`PATTERN_WIDTH-1:0] pattern
);

reg [`PATTERN_WIDTH-1:0] patterns_table [2**`BHT_PC_HASH_WIDTH-1: 0];
assign pattern = patterns_table[hash_pc];

// first half cycle: update
always @(negedge clk) begin
    if (reset) begin 
        for (int i = 0; i < 2**`BHT_PC_HASH_WIDTH; i+=1) begin
            patterns_table[i] = 0;
        end
    end
    // update on negedge
    else if (enupdate) begin
        patterns_table[hash_pc][`PATTERN_WIDTH-1] = is_branch;
    end
end

endmodule
