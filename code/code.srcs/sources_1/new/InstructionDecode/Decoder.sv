`include "IDPhaseConfig.svh" 
`include "IDPhaseStruct.svh"

module Decoder(
    input wire [`INST_WIDTH-1: 0] instruction [`MACHINE_WIDTH],
    output InstructionInfo instruction_info [`MACHINE_WIDTH]
);

// Decode is completely combine unit

always_comb begin 
    for (int i = 0; i < `MACHINE_WIDTH; i += 1) begin 
        // initialize default value
        instruction_info[i].dest_valid = 1'b0;
        instruction_info[i].srcL_valid = 1'b0;
        instruction_info[i].srcR_valid = 1'b0;
        instruction_info[i].shamt = 1'b0;
        instruction_info[i].imm16_valid = 1'b0;
        instruction_info[i].imm26_valid = 1'b0;
        instruction_info[i].slt_trans = 1'b0;
        instruction_info[i].need_log = 1'b0;
        instruction_info[i].is_direct_branch = 1'b0;
        instruciton_info[i].is_cond_branch = 1'b0;

        case (instruction[i][31: 26])
            // R type instructions ================================
            6'b000000: begin 
                case (instruction[i][5: 0]) // discuss func code  
                    // SLT is also implement by subtraction
                    // instructions executed with simple ALU

                    // ADD, ADDU, SUB, SUBU, SLT, SLTU
                    // AND, OR, XOR, NOR
                    6'b100000, 6'b100001, 6'b100010, 6'b100011, 6'b101010, 6'b101011,
                    6'b100100, 6'b100101, 6'b100110, 6'b100111: begin 
                        instruction_info[i].srcL_valid = 1'b1;
                        instruction_info[i].srcL = instruction[i][25: 21];
                        instruction_info[i].srcR_valid = 1'b1;
                        instruction_info[i].srcR = instruction[i][20: 16];
                        instruction_info[i].dest_valid = 1'b1;
                        instruction_info[i].dest = instruction[i][15:11];
                        instruction_info[i].op_type = SIMPLE_ALU;
                        // the least three bits decide computing type
                        // ADD, ADDU
                        if (instruction[i][2:0]==3'b000 || instruction[i][2:0]==3'b001) begin 
                            instruction_info[i].salu_op = ALU_ADD;
                        end
                        // SUB, SUBU, SLT, SLTU
                        else if (instruction[i][2:0]==3'b010 || instruction[i][2:0]==3'b011) begin 
                            instruction_info[i].salu_op = ALU_SUB;
                            instruction_info[i].slt_trans = instruction[i][3]; // SLT, SLTU
                        end 
                        // AND
                        else if (instruction[i][2:0]==3'b100) begin 
                            instruction_info[i].salu_op = ALU_AND;
                        end 
                        // OR
                        else if (instruction[i][2:0]==3'b101) begin 
                            instruction_info[i].salu_op = ALU_OR;
                        end 
                        // XOR
                        else if (instruction[i][2:0]==3'b110) begin
                            instruction_info[i].salu_op = ALU_XOR; 
                        end 
                        // NOR
                        else if (instruction[i][2:0]==3'b111) begin
                            instruction_info[i].salu_op = ALU_NOR; 
                        end 
                    end
                    // MULT, MULTU, DIV, DIVU
                    // instructions executed with complex ALU
                    6'b011000, 6'b011001, 6'b011010, 6'b011011: begin 
                        instruction_info[i].srcL_valid = 1'b1;
                        instruction_info[i].srcL = instruction[i][25: 21];
                        instruction_info[i].srcR_valid = 1'b1;
                        instruction_info[i].srcR = instruction[i][20: 16];
                        instruction_info[i].op_type = COMPLEX_ALU;
                        if (instruction[i][1] == 1'b1) begin // DIV, DIVU   
                            instruction_info[i].calu_op = ALU_DIV;
                        end 
                        else if (instruction[i][1] == 1'b0) begin // MULT, MULTU
                            instruction_info[i].calu_op = ALU_MUL;
                        end
                    end
                    // instructions executed with shift function unit
                    // SLLV, SRAV, SRLV
                    // SLL, SRA, SRL
                    6'b000100, 6'b000111, 6'b000110, 
                    6'b000000, 6'b000011, 6'b000010: begin 
                        instruction_info[i].srcL_valid = instruction[i][2]; // ending-V can be differenced by least-3 bit
                        instruction_info[i].srcL = instruction[i][25: 21];
                        instruction_info[i].srcR_valid = 1'b1;
                        instruction_info[i].srcR = instruction[i][20: 16];
                        instruction_info[i].dest_valid = 1'b1;
                        instruction_info[i].dest = instruction[i][15:11];
                        instruction_info[i].shamt_valid = ~instruction[i][2];
                        instruction_info[i].shamt = instruction[i][10:6];
                        instruction_info[i].op_type = SHIFT;
                        if (instruction[i][1:0] == 2'b00) begin // SLLV, SLL 
                            instruction_info[i].shift_type = LEFT;
                        end 
                        else if (instruction[i][1:0] == 2'b11) begin // SRAV, SRA
                            instruction_info[i].shift_type = A_RIGHT;
                        end 
                        else if (instruction[i][1:0] == 2'b10) begin 
                            instruction_info[i].shift_type = L_RIGHT;
                        end
                    end
                    // instructions executed with unconditional branch function unit
                    // JR, JALR
                    6'b001000, 6'b001001: begin 
                        instruction_info[i].srcL_valid = 1'b1;
                        instruction_info[i].srcL = instruction[i][25: 21];
                        instruction_info[i].dest_valid = instruction[i][0];
                        instruction_info[i].dest = instruction[i][15:11];
                        instruction_info[i].need_log = instruction[i][0]; // JALR
                        instruction_info[i].op_type = BRANCH;
                        // instruction_info[i].is_direct_branch = 1'b1;
                    end 
                    // instructions executed with coprocess function unit
                    // MFHI, MTHI, MFLO, MTLO
                    6'b010000, 6'b010001, 6'b010010, 6'b010011: begin 
                        instruction_info[i].srcL_valid = instruction[i][0];
                        instruction_info[i].srcL = instruction[i][25: 21];
                        instruction_info[i].dest_valid = ~instruction[i][0];
                        instruction_info[i].dest = instruction[i][15:11];
                        nstruction_info[i].op_type = MOVE;
                        case (instruction[i][1:0])
                            2'b00: instruction_info[i].move_type = HI2REG;
                            2'b01: instruction_info[i].move_type = REG2HI;
                            2'b10: instruction_info[i].move_type = LO2REG;
                            2'b11: instruction_info[i].move_type = REG2LO;
                        endcase 
                    end 
                    // syscall
                    6'b001100: begin 
                        instruction_info[i].op_type = FINISH;
                    end 
                endcase
            end
            // I type instructions ================================ 
            // instructions executed with simple ALU
            // ADDI, ADDIU, SLTI, SLTIU, ANDI, ORI, XORI
            6'b001000, 6'b001001, 6'b001010, 6'b001011, 6'b001100, 6'b001101, 6'b001110: begin 
                instruction_info[i].srcL_valid = 1'b1;
                instruction_info[i].srcL = instruction[i][25: 21];
                instruction_info[i].imm16_valid = 1'b1;
                instruction_info[i].imm16 = instruction[i][15:0];
                instruction_info[i].dest_valid = 1'b1;
                instruction_info[i].dest = instruction[i][20: 16];
                instruction_info[i].op_type = SIMPLE_ALU;
                case (instruction[i][29:26])
                    4'b1000, 4'b1001: begin 
                        instruction_info[i].salu_op = ALU_ADD;
                    end 
                    4'b1010, 4'b1011: begin 
                        instruction_info[i].salu_op = ALU_SUB;
                        instruction_info[i].slt_trans = 1'b1;
                    end 
                    4'b1100: begin 
                        instruction_info[i].salu_op = ALU_AND;
                    end 
                    4'b1101: begin 
                        instruction_info[i].salu_op = ALU_OR;
                    end 
                    4'b1110: begin
                        instruction_info[i].salu_op = ALU_XOR;
                    end 
                endcase
            end 
            // LUI
            6'b001111: begin 
                instruction_info[i].imm16_valid = 1'b1;
                instruction_info[i].imm16 = instruction[i][15:0];
                instruction_info[i].dest_valid = 1'b1;
                instruction_info[i].dest = instruction[i][20:16];
                instruction_info[i].salu_op = ALU_OR;
                instruction_info[i].op_type = SIMPLE_ALU;
            end 
            // instructions executed with conditional branch function unit
            // two operands instruction: 
            // BEQ, BNE, defautly, use subtraction operation
            6'b000100, 6'b000101: begin 
                instruction_info[i].srcL_valid = 1'b1;
                instruction_info[i].srcL = instruction[i][25: 21];
                instruction_info[i].srcR_valid = 1'b1;
                instruction_info[i].srcR = instruction[i][20: 16];
                instruction_info[i].imm16_valid = 1'b1;
                instruction_info[i].imm16 = instruction[i][15: 0];
                instruction_info[i].op_type = BRANCH;
                instruciton_info[i].is_cond_branch = 1'b1;
                if (instruction[i][26]) begin
                    instruction_info[i].comp_type = NE;
                end 
                else begin 
                    instruction_info[i].comp_type = EQ;
                end 
            end  
            // single operand instruction:
            // BGEZ, BLTZ
            6'b000001: begin 
                instruction_info[i].srcL_valid = 1'b1;
                instruction_info[i].srcL = instruction[i][25: 21];
                instruction_info[i].imm16_valid = 1'b1;
                instruction_info[i].imm16 = instruction[i][15:0];
                instruction_info[i].op_type = BRANCH;
                instruciton_info[i].is_cond_branch = 1'b1;
                if (instruction[i][16]) begin 
                    instruction_info[i].comp_type = GEZ;
                end 
                else begin
                    instruction_info[i].comp_type = LTZ;
                end 
            end 
            // BGTZ, BLEZ
            6'b000111, 000110: begin 
                instruction_info[i].srcL_valid = 1'b1;
                instruction_info[i].srcL = instruction[i][25: 21];
                instruction_info[i].imm16_valid = 1'b1;
                instruction_info[i].imm16 = instruction[i][15:0];
                instruction_info[i].op_type = BRANCH;
                instruciton_info[i].is_cond_branch = 1'b1;
                if (instruction[i][26]) begin 
                    instruction_info[i].comp_type = GTZ;
                end
                else begin 
                    instruction_info[i].comp_type = LEZ;
                end 
            end 
            // BGEZAL, BLTZAL
            6'b000001: begin 
                instruction_info[i].srcL_valid = 1'b1;
                instruction_info[i].srcL = instruction[i][25: 21];
                instruction_info[i].imm16_valid = 1'b1;
                instruction_info[i].imm16 = instruction[i][15:0];
                instruction_info[i].need_log = 1'b1;
                instruction_info[i].op_type = BRANCH;
                instruciton_info[i].is_cond_branch = 1'b1;
                if (instruction[i][16]) begin 
                    instruction_info[i].comp_type = GEZ;
                end
                else begin
                    instruction_info[i].comp_type = LTZ;
                end 
            end 
            // memory operations
            // LB, LBU, LH, LHU, LW
            6'b100000, 6'b100100, 6'b100001, 6'b100101, 6'b100011: begin 
                instruction_info[i].srcL_valid = 1'b1;
                instruction_info[i].srcL = instruction[i][25:21];
                instruction_info[i].imm16_valid = 1'b1;
                instruction_info[i].imm16 = instruction[i][15:0];
                instruction_info[i].dest_valid = 1'b1;
                instruction_info[i].dest = instruction[i][20:16];
                instruction_info[i].mem_type = MEM2REG;
                instruction_info[i].op_type = MEMORY;
                case (instruction[i][27:26])
                    2'b00: instruction_info[i].load_size = BYTE; 
                    2'b01: instruction_info[i].load_size = HEX;
                    2'b11: instruction_info[i].load_size = WORD;
                endcase
                if (instruction[i][28] == 1'b1) begin // LBU, LHU
                    instruction_info[i].ext_type = UNSIGNED;
                end 
                else begin // LB, LH
                    instruction_info[i].ext_type = SIGNED; 
                end 
            end 
            // SB, SH, SW
            6'b101000, 6'b101001, 6'b101011: begin 
                // AGU will take srcL and imm16 to generate address
                instruction_info[i].srcL_valid = 1'b1;
                instruction_info[i].srcL = instruction[i][25:21];
                instruction_info[i].imm16_valid = 1'b1;
                instruction_info[i].imm16 = instruction[i][15:0];
                // Store instruction's srcR is used to supply data to store
                instruction_info[i].srcR_valid = 1'b1;
                instruction_info[i].srcR = instruction[i][20:16];
                instruction_info[i].mem_type = REG2MEM;
                instruction_info[i].op_type = MEMORY;
                case (instruction[i][27:26])
                    2'b00: instruction_info[i].load_size = BYTE; 
                    2'b01: instruction_info[i].load_size = HEX;
                    2'b11: instruction_info[i].load_size = WORD;
                endcase
            end 
            // J type instructions ================================ 
            // J, JAL
            6'b000010, 6'b000011: begin 
                instruction_info[i].imm26_valid = 1'b1;
                instruction_info[i].imm26 = instruction[i][25: 0];
                instruction_info[i].need_log = instruction[i][26];
                instruction_info[i].is_direct_branch = 1'b1;
                instruction_info[i].op_type = BRANCH;
            end 
        endcase
    end
end

endmodule