`include "IDPhaseConfig.svh"
`include "../InstructionFetch/IFPhaseConfig.svh"

module InstructionBuffer #(
    parameter IB_SIZE = 1000
) (
    input wire clk,
    input wire reset,
    input wire read_en,
    input wire write_en,
    input wire [`IF_GROUP_SIZE-1: 0] num_valid,
    input wire [`INST_WIDTH-1: 0] inst_in [`IF_GROUP_SIZE],  
    output wire [`INST_WIDTH-1: 0] inst_out [`MACHINE_WIDTH],  
    output wire almost_full,
    output wire almost_empty
);

// buffer size: 2^{10} = 1024, actually use: 1000

// a multi port FIFO is very ineffictive, use multi single port FIFO to replayce it
reg [`INST_WIDTH-1: 0] reg_inst_out [`MACHINE_WIDTH]; 

reg [`IB_INDEX_WIDTH-1: 0] write_ptr;
reg [`IB_INDEX_WIDTH-1: 0] read_ptr;

reg [`INST_WIDTH-1: 0] inst_buffer [IB_SIZE];

wire [`IB_INDEX_WIDTH-1: 0] wptrs [`IF_GROUP_SIZE];
wire [`IB_INDEX_WIDTH-1: 0] rptrs [`MACHINE_WIDTH];

reg [`IB_INDEX_WIDTH: 0] num_items;

assign almost_full = (num_items + `IF_GROUP_SIZE) < IB_SIZE;
assign almost_empty = (num_items - `MACHINE_WIDTH) < 0;

generate
    for (genvar j = 0; j < `MACHINE_WIDTH; j += 1) begin 
        assign inst_out[j] = reg_inst_out[j];
    end 
    for (genvar j = 0; j < `MACHINE_WIDTH; j += 1) begin 
        assgin rptrs[j] = (read_ptr + j) % IB_SIZE;
    end 
    for (genvar j = 0; j < `IF_GROUP_SIZE; j += 1) begin 
        assign wptrs[j] = (write_ptr + j) % IB_SIZE;
    end 
endgenerate

always_ff @(posedge clk) begin 
    if (reset) begin 
        write_ptr <= `IB_INDEX_WIDTH'b0;
        read_ptr <= `IB_INDEX_WIDTH'b0;
        num_items <= 0;
        for (int i = 0; i < IB_SIZE; i += 1) begin 
            inst_buffer[i] <= `INST_WIDTH'b0;
        end     
    end 
    if (read_en) begin 
        if (!almost_empty) begin 
            for (int i = 0; i < `MACHINE_WIDTH; i += 1) begin
                reg_inst_out[i] <= inst_buffer[rptrs[i]];
            end
            read_ptr <= (read_ptr + `MACHINE_WIDTH) % IB_SIZE;
            num_items <= num_items - `MACHINE_WIDTH;
        end 
    end 
    if (write_en) begin 
        if (!almost_full) begin 
            for (int i = 0; i < num_valid; i += 1) begin 
                inst_buffer[wptrs[i]] <= inst_in[i];
            end 
            write_ptr <= (write_ptr + num_valid) % IB_SIZE;
            num_items <= num_items + num_valid;
        end 
    end 
    // the data read is wriiten in the last cycle at the begining
end 

endmodule