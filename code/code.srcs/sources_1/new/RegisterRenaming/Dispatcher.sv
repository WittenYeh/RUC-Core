`include "./RRPhaseConfig.svh"
`include "../InstructionDecode/IDPhaseStruct.svh"

// the dispatcher will send the instructions to different issue queue
module Dispatcher #(
    
) (
    input InstructionInfo inst_info_in [`DISPATCH_WIDTH],
    output InstructionInfo mem_queue [`DISPATCH_WIDTH],
    output wire [`DISPATCH_WIDTH: 0] num_mem_inst, 
    output InstructionInfo salu_queue [`DISPATCH_WIDTH],
    output wire [`DISPATCH_WIDTH: 0] num_salu_inst,
    output InstructionInfo calu_queue [`DISPATCH_WIDTH],
    output wire [`DISPATCH_WIDTH: 0] num_calu_inst,
    output InstructionInfo branch_queue [`DISPATCH_WIDTH],
    output wire [`DISPATCH_WIDTH: 0] num_branch_inst
);

reg [`DISPATCH_WIDTH: 0] reg_num_mem_inst;
reg [`DISPATCH_WIDTH: 0] reg_num_salu_inst;
reg [`DISPATCH_WIDTH: 0] reg_num_calu_inst;
reg [`DISPATCH_WIDTH: 0] reg_num_branch_inst;

assign num_mem_inst = reg_num_mem_inst;
assign num_calu_inst = reg_num_calu_inst;
assign num_salu_inst = reg_num_salu_inst;
assign num_branch_inst = reg_num_branch_inst;

always_comb begin 
    reg_num_salu_inst = 0;
    reg_num_salu_inst = 0;
    reg_num_branch_inst = 0;
    reg_num_mem_inst = 0;
    for (int i = 0; i < `DISPATCH_WIDTH; i += 1) begin 
        if ( inst_info_in[i].op_type == SIMPLE_ALU ||
            inst_info_in[i].op_type == SHIFT ||
            inst_info_in[i].op_type == MOVE
        ) begin
            salu_queue[reg_num_salu_inst] = inst_info_in[i];
            reg_num_salu_inst += 1;
        end
        else if (inst_info_in[i].op_type == COMPLEX_ALU) begin 
            calu_queue[reg_num_calu_inst] = inst_info_in[i];
            reg_num_calu_inst += 1;
        end 
        else if (inst_info_in[i].op_type == BRANCH) begin 
            branch_queue[reg_num_branch_inst] = inst_info_in[i];
            reg_num_branch_inst += 1;
        end 
        else if (inst_info_in[i].op_type == MEMORY) begin 
            branch_queue[reg_num_mem_inst] = inst_info_in[i];
            reg_num_mem_inst += 1;
        end 
        else if (inst_info_in[i].op_type == FINISH) begin 
            // finish logic
        end 
    end 
end 

endmodule