`include "../RegisterRenaming/RRPhaseConfig.svh"
`include "../InstructionDecode/IDPhaseStruct.svh"
`include "../Issue/IssuePhaseConfig.svh"
`include "../Issue/IssuePhaseStruct.svh"

module PayloadRAM #(
    PR_SIZE = 2 ** `ROB_INDEX_WIDTH
) (
    input wire clock,
    input wire reset,
    input wire write_en,
    input wire read_en,
    input wire capture_en,
    
    input PayloadEntry entry_in [`MACHINE_WIDTH],
    
    input wire [`ROB_INDEX_WIDTH-1: 0] write_addr [`MACHINE_WIDTH],   // write in renaming phase 
    input wire [`ROB_INDEX_WIDTH-1: 0] read_addr [`ISSUE_WIDTH],        // read in execute phase
    
    input wire [`ROB_INDEX_WIDTH-1: 0] bypass_bus_robid [`ISSUE_WIDTH],   // rob id broadcast by bypass network
    input wire [`REG_WIDTH-1: 0] bypass_bus_value [`ISSUE_WIDTH],         // the corresponding value broadcast by bypass network
    input wire bypass_bus_valid [`ISSUE_WIDTH],    // whether bypass bus is useful or not 
    
    output wire srcL_ready [PR_SIZE],            // to indicate whether the source of this instruction is ready
    output wire srcR_ready [PR_SIZE],
    output PayloadEntry entry_out [`ISSUE_WIDTH] // when reading by 
);
    
PayloadEntry entries [PR_SIZE];

generate
    for (genvar i = 0; i < PR_SIZE; i += 1) begin 
        assign srcL_ready[i] = entries[i].srcL_ready;
        assign srcR_ready[i] = entries[i].srcR_ready;
    end 
endgenerate

// payload ram is strictly corresponding to ROB
// ROB stores pysical register index
// PayloadRAM stores its value
// write ROB in first half cycle 
// write payload ram in second half cycle
always_ff @(negedge clock) begin
    // set all 
    if (reset) begin 
        for (int i = 0; i < PR_SIZE; i += 1) begin 
            entries[i].occurpied = 1'b0;
        end
    end 
    
    // write latest entries from ROB to payload
    if (write_en) begin 
        for (int i = 0; i < `MACHINE_WIDTH; i += 1) begin 
            entries[write_addr[i]] = entry_in[i]; // this operation will set the correspoding bit true
        end     
    end 
    
    // read data for execution
    // each issue queue use a port to read
    if (read_en) begin 
        for (int i = 0; i < `ISSUE_WIDTH; i += 1) begin 
            entry_out[i] = entries[write_addr[i]];
        end   
    end 

    // capture data from bypass network
    if (capture_en) begin 
        for (int i = 0; i < `ISSUE_WIDTH; i += 1) begin 
            // if the excuted instruction has no rd field, no need to update any entry in payload
            if (bypass_bus_valid[i]) begin 
                // broadcast to all entries in payload
                for (int j = 0; j < PR_SIZE; j += 1) begin 
                    // to check whether the ROB id match the source register
                    // discuss left src
                    if ( entries[j].occurpied && 
                        // entries[j].srcL_valid &&
                        entries[j].srcL_robid == bypass_bus_robid[i]
                    ) begin 
                        entries[j].srcL_value = bypass_bus_value[i];
                        entries[j].srcL_ready = 1'b1;
                    end 
                    // discuss right src
                    if ( entries[j].occurpied && 
                        // entries[j].srcR_valid &&
                        entries[j].srcR_robid == bypass_bus_robid[i]
                    ) begin 
                        entries[j].srcR_value = bypass_bus_value[i];
                        entries[j].srcR_ready = 1'b1;
                    end 
                end 
            end
        end 
    end 
end

endmodule