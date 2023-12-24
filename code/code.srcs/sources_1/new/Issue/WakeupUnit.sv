`include "./IssuePhaseConfig.svh"
`include "./IssuePhaseStruct.svh"

module WakeupUnit #(
    
) (
    input IQEntry iq_entry,
    output wire wake_up
);
    
reg reg_wake_up;
assign wake_up = reg_wake_up;

always_comb begin 
    reg_wake_up = 1'b1;
    if (iq_entry.inst_info.srcL_valid) begin 
        if (!(iq_entry.bc_srcL_ready || iq_entry.pr_srcL_ready)) begin 
            reg_wake_up = 1'b0;
        end 
    end 
    if (iq_entry.inst_info.srcR_valid) begin 
        if (!(iq_entry.bc_srcR_ready || iq_entry.pr_srcR_ready)) begin 
            reg_wake_up = 1'b0;
        end 
    end 
end 

endmodule