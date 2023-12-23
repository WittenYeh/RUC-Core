`include "IFPhaseConfig.svh"
`include "IFPhaseStruct.svh"
`include "../Commit/CommitPhaseConfig.svh"

/* 
 * enupdate: update when a branch instruction commit
 * index: the index of instructions
 * isbranch_in
 */

module PatternHistoryTable (
    input wire clk,
    input wire reset,
    input wire enupdate,
    input wire [`PHT_INDEX_WIDTH-1: 0] read_index [`IF_GROUP_SIZE],
    input wire [`PHT_INDEX_WIDTH-1: 0] write_index [`COMMIT_WIDTH],
    input wire isbranch_in [`COMMIT_WIDTH],
    output wire isbranch_out [`IF_GROUP_SIZE]
);

ImodalCounterState bimodal_counter [2**`PHT_INDEX_WIDTH];

reg reg_isbranch_out [`IF_GROUP_SIZE];
generate
    for (genvar j = 0; j < `IF_GROUP_SIZE; j += 1) begin
        assgin isbranch_out[j] = reg_isbranch_out[j];
    end
endgenerate

always_ff@(posedge clk) begin 
    if (reset) begin 
        for (int i = 0; i < 2**`PHT_INDEX_WIDTH; i += 1) begin 
            bimodal_counter[i] = WEALY_NOT_TAKEN;
        end 
    end
    // update
    else if (enupdate) begin
        for (int i = 0; i < `COMMIT_WIDTH; i += 1) begin 
            case (bimodal_counter[write_index[i]])
                STRONGLY_NOT_TAKEN: begin
                    if (isbranch_in[i]) begin // branch happen
                        bimodal_counter[write_index[i]] <= WEALY_NOT_TAKEN;
                    end 
                    else begin // branch not happen
                        bimodal_counter[write_index[i]] <= STRONGLY_NOT_TAKEN;
                    end 
                end
                WEALY_NOT_TAKEN: begin 
                    if (isbranch_in[i]) begin // branch happen
                        bimodal_counter[write_index[i]] <= WEAKLY_TAKEN;
                    end 
                    else begin // branch not happen
                        bimodal_counter[write_index[i]] <= STRONGLY_NOT_TAKEN;
                    end 
                end
                WEAKLY_TAKEN: begin 
                    if (isbranch_in[i]) begin // branch happen 
                        bimodal_counter[write_index[i]] <= STRONGLY_TAKEN;
                    end 
                    else begin // branch not happen
                        bimodal_counter[write_index[i]] <= WEALY_NOT_TAKEN;
                    end
                end 
                STRONGLY_TAKEN: begin 
                    if (isbranch_in[i]) begin // branch happen
                        bimodal_counter[write_index[i]] <= STRONGLY_TAKEN;
                    end 
                    else begin // branch not happen
                        bimodal_counter[write_index[i]] <= WEAKLY_TAKEN;
                    end 
                end 
            endcase
        end 
    end
end 

// read
always_comb begin 
    for (int i = 0; i < `IF_GROUP_SIZE; i += 1) begin 
        case (bimodal_counter[read_index[i]])
            STRONGLY_NOT_TAKEN, WEALY_NOT_TAKEN: begin 
                reg_isbranch_out[i] = 0;
            end
            WEAKLY_TAKEN, STRONGLY_TAKEN: begin
                reg_isbranch_out[i] = 1;
            end
        endcase
    end
end

endmodule