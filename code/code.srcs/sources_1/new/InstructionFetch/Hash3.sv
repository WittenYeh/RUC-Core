`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/04 17:55:39
// Design Name: 
// Module Name: Hash3
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

module Hash3(
    input wire[`INST_ADDR_WIDTH-1: 0] pc,
    output wire[`BHT_INDEX_WIDTH+1: 2] result
);

assign result = pc[`BHT_INDEX_WIDTH+1: 2];

endmodule
