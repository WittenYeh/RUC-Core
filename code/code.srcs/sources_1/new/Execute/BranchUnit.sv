`include "../InstructionDecode/IDPhaseStruct.svh"
`include "../InstructionFetch/IFPhaseConfig.svh"
`include "../Issue/IssuePhaseStruct.svh"

// the main funtion of the branch unit is to verify whether the predicted result is right
module BranchUnit #(
    
) (
    input InstructionInfo inst_info_in,
    input PayloadEntry payload,
    output wire is_mispred,
    output wire [`INST_ADDR_WIDTH-1: 0] actual_addr
);
    
reg reg_is_mispred;
reg [`INST_ADDR_WIDTH-1: 0] reg_actual_addr;

assign is_mispred = reg_is_mispred;
assign actual_addr = reg_actual_addr;

// just need to use combinatorial logic
always_comb begin
    // $assert (inst_info_in.op_type == BRANCH) 
    // else   $display("misdispatch instruction %h to branch unit", );
    reg_is_mispred = 1'b0; 
    
    // branch instruction type judge should be finished in decode stage 

    // if (inst_info_in.pred_branch == 1'b0) begin 
    //     reg_is_mispred = 1'b1;
    // end 
    // J and JAL
    
    if (inst_info_in.is_direct_branch) begin 
        reg_actual_addr = {inst_info_in.pc_value[31:28], inst_info_in.imm26, 2'b00};
        if (reg_actual_addr != inst_info_in.pred_addr) begin 
            reg_is_mispred = 1'b1;
        end 
    end 
    // BEQ, BNE, BGEZ, BLTZ, BGTZ, BLEZ, BGEZAL, BLTZAL
    else if (inst_info_in.is_cond_branch) begin 
        case (inst_info_in.comp_type)
            EQ: begin 
                
            end 
            NE: begin 

            end 
            GEZ: begin 

            end 
            GTZ: begin 

            end 
            LEZ: begin

            end 
            LTZ: begin 

            end  
        endcase
    end 
    // JR, JALR
    else begin 
        
    end 
end

endmodule