// return the min

module MIN #(
    INPUT_WIDTH = 2, // default input width
    INPUT_SIZE = 32   // defallt input item size
) (
    input wire [INPUT_SIZE-1: 0] data_in [INPUT_WIDTH],
    output wire [INPUT_SIZE-1: 0] result 
);

reg [INPUT_SIZE-1: 0] min_data;
    
assign result = min_data;

always_comb begin
    min_data = {INPUT_SIZE{1'b1}};
    for (int i = 0; i < INPUT_WIDTH; i += 1) begin 
        if (data_in[i] < min_data) begin 
            min_data = data_in[i];
        end 
    end 
end

endmodule