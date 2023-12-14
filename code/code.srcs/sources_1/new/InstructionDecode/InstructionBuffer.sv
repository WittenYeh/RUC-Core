`include "IDPhaseConfig.svh"
`include "../InstructionFetch/IFPhaseConfig.svh"

module InstructionBuffer(
    input wire clk,
    input wire reset,
    input wire read_en,
    input wire write_en,
    input wire inst_valid [`IF_GROUP_SIZE],
    input wire [`INST_WIDTH-1: 0] inst_in [`IF_GROUP_SIZE],
    output wire [`INST_WIDTH-1: 0] inst_out [`MACHINE_WIDTH],
    output wire almost_full,
    output wire almost_empty
);

// a multi port FIFO is very ineffictive, use multi single port FIFO to replayce it

reg [`INST_WIDTH-1: 0] inst_buffer [`IB_SIZE];


// both read_ptr and write_ptr have a flag bit to record whether the ptr finish a sequencial loop or not
reg unsigned [`IB_INDEX_WIDTH-1: 0] read_ptr;
reg unsigned [`IB_INDEX_WIDTH-1: 0] nxt_read_ptr;
reg read_loop_flag;

reg unsigned [`IB_INDEX_WIDTH-1: 0] write_ptr;
reg unsigned [`IB_INDEX_WIDTH-1: 0] nxt_write_ptr;
reg write_loop_flag;

wire unsigned [`IB_INDEX_WIDTH-1: 0] rptrs [`MACHINE_WIDTH];
wire unsigned [`IB_INDEX_WIDTH-1: 0] wptrs [`IF_GROUP_SIZE];
generate 
    for (genvar j = 0; j < `MACHINE_WIDTH; j += 1) begin
        assign rptrs[j] = read_ptr + 1;
    end 
    for (genvar j = 0; j < `IF_GROUP_SIZE; j += 1) begin 
        assign wptrs[j] = write_ptr + 1;
    end 
endgenerate

// when read_ptr equals to write_ptr, there are two situations:
// FIFO full, if read_ptr's flag is not equals to write_ptr's flag
// FIFO empty, if write_ptr's flag is equals to read_ptr's flag

wire [`IB_INDEX_WIDTH-1:0] max_read_ptr;
wire [`IB_INDEX_WIDTH-1:0] min_read_ptr;
wire [`IB_INDEX_WIDTH-1:0] max_write_ptr;
wire [`IB_INDEX_WIDTH-1:0] min_write_ptr;

// assign max_read_ptr = read_ptr[`MACHINE_WIDTH-1];
assign min_read_ptr = read_ptr[0];
// assign max_write_ptr = write_ptr[`MACHINE_WIDTH-1];
assign min_write_ptr = write_ptr[0];

// max_read_ptr almost catch up with min_write_ptr
assign almost_empty = (read_loop_flag==write_loop_flag) && (max_read_ptr+`MACHINE_WIDTH>=min_write_ptr-1);
// max_write_ptr almost catch up with min_read_ptr
assign almost_full = (read_loop_flag!=write_loop_flag) && (max_write_ptr+`MACHINE_WIDTH>=min_read_ptr-1);

reg [`INST_WIDTH-1: 0] reg_inst_out [`MACHINE_WIDTH];
reg [4:0] num_valid_inst;

generate
    for (genvar j = 0; j < `MACHINE_WIDTH; j += 1) begin 
        assign inst_out[j] = reg_inst_out[j];
    end 
endgenerate

// write_ptr move logic
always_comb begin 
    
end 

// read_ptr move logic
always_comb begin 

end

always_comb begin
    for (int i = 0; i < `MACHINE_WIDTH; i += 1) begin 
        num_valid_inst += inst_valid[i];
    end 
end

always_ff @(posedge clk) begin
    if (reset) begin
        read_loop_flag <= 1'b0;
        write_loop_flag <= 1'b0;
        for (int i = 0; i < `IF_GROUP_SIZE; i += 1) begin 
            reg_inst_out[i] <= `INST_WIDTH'b0;
        end
        for (int i = 0; i < `MACHINE_WIDTH; i += 1) begin 

        end
    end
    // Read when writing is OK, because read_ptr never insect with write ptr 
    if (read_en) begin 
        

    end 
    if (write_en) begin 
        
    end
end

endmodule