// return the max 

module MAX #(
    INPUT_WIDTH = 2, // default input width
    INPUT_SIZE = 32   // defallt input item size
) (
    input wire [INPUT_SIZE-1: 0] data_in [INPUT_WIDTH],
    output wire [INPUT_SIZE-1: 0] result 
);

reg [INPUT_SIZE-1: 0] max_data;
    
assign result = max_data;

always_comb begin
    max_data = INPUT_SIZE'('b0);
    for (int i = 0; i < INPUT_WIDTH; i += 1) begin 
        if (data_in[i] > max_data) begin 
            max_data = data_in[i];
        end 
    end 
end

endmodule