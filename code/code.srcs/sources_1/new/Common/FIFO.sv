module FIFO # (
    parameter ITEM_SIZE = 32,
    parameter INDEX_WIDTH = 10,
    parameter FIFO_SIZE = 2**INDEX_WIDTH
) (
    input wire clk,
    input wire reset,
    input wire read_en,
    input wire write_en,
    input wire [ITEM_SIZE-1: 0] data_in,
    output wire [ITEM_SIZE-1: 0] data_out,
    output wire is_full,
    output wire is_empty
);

reg [ITEM_SIZE-1: 0] fifo_buffer [FIFO_SIZE];

reg [ITEM_SIZE-1: 0] reg_data_out;
assign data_out = reg_data_out;
reg [INDEX_WIDTH-1: 0] write_ptr;
reg [INDEX_WIDTH-1: 0] read_ptr;
reg [INDEX_WIDTH: 0] num_items;

assign is_full = num_items==FIFO_SIZE;
assign is_empty = num_items==0;

always_ff @(posedge clk) begin 
    if (reset) begin 
        write_ptr <= 0;
        read_ptr <= 0;
        num_items <= 0;        
    end 
    if (read_en && write_en) begin 
        assert(read_ptr != write_ptr); // full or empty
        reg_data_out <= fifo_buffer[read_ptr];
    end 
    else if (read_en) begin 
        assert(num_items != 0);
        reg_data_out <= fifo_buffer[read_ptr];
        read_ptr <= (read_ptr + 1) % FIFO_SIZE;
        num_items <= num_items + 1;
    end 
    if (write_en) begin 
        assert(num_items != FIFO_SIZE);
        fifo_buffer[write_ptr] <= data_in;
        write_ptr <= (write_ptr + 1) % FIFO_SIZE;
        num_items <= num_items + 1;
    end 
end 

endmodule