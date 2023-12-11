`ifndef ID_PHASE_STRUCT
`define ID_PHASE_STRUCT

`include "./IDPhaseConfig.svh"
`include "../RegisterRenaming/RRPhaseConfig.svh"

typedef enum {
    // Corrsponding to each issue queue (except syscall)
    SIMPLE_ALU,
    COMPLEX_ALU,
    SHIFT,
    BRANCH,
    MEMORY,
    MOVE,
    FINISH
} IssueType;

typedef enum {
    // R type
    // opcode = 000000
    ADD, // func = 100000
    ADDU, // func = 100001
    SUB,  // func = 100010
    SUBU, // func = 100011
    SLT, // func = 101010
    SLTU, // func = 101011
    
    DIV, // func = 011010
    DIVU, // func = 011011
    MULT, // func = 011000
    MULTU, // func = 011001
    
    AND,  // func = 100100
    NOR, // func = 100111
    OR, //func = 100101
    XOR, // func = 100110
    
    SLLV, // func = 000100
    SLL, // func = 000000
    SRAV, // func = 000111
    SRA, // func = 000011
    SRLV, // func = 000110
    SRL, // func = 000010

    JR, // func = 001000
    JALR, // func = 001001

    MFHI, // func = 010000
    MTHI, // func = 010001
    MFLO, // func = 010010
    MTLO, // func = 010011

    SYSCALL, // func = 001100
    
    // =============================================== //

    // I type
    ADDI, // opcode = 001000
    ADDIU, // opcode = 001001
    SLTI, // opcode = 001010
    SLTIU, // opcode = 001011 
    ANDI, // opcode = 001100
    ORI, // opcode = 001101
    XORI, // opcode = 001110

    LUI, // opcode = 001111

    BEQ, // opcode = 000100
    BNE, // opcode = 000101
    BGEZ, // opcode = 000001
    BGTZ, // opcode = 000111
    BLEZ, // opcode = 000110
    BLTZ, // opcode = 000001
    BGEZAL, // opcode = 000001
    BLTZAL, // opcode = 000001

    LB, // opcode = 100000
    LBU, // opcode = 100100
    LH, // opcode = 100001
    LHU, // opcode = 100101
    LW, // opcode = 100011
    SB, // opcode = 101000
    SH, // opcode = 101001
    SW, // opcode = 101011

    // =============================================== //

    // J Type
    J, // opcode = 000010
    JAL // opcode = 000011,
} InstrucionType;

typedef enum { 
    ALU_ADD, 
    ALU_SUB,
    ALU_OR, 
    ALU_XOR,
    ALU_NOR,
    ALU_AND
} SIMPLE_ALU_OP;

typedef enum {
    ALU_DIV,
    ALU_MUL
} COMPLEX_ALU_OP;

typedef enum {
    LEFT,
    A_RIGHT,
    L_RIGHT
} SHIFT_TYPE;

typedef enum {
    HI2REG,
    REG2HI,
    LO2REG,
    REG2LO
} MOVE_TYPE;

typedef enum { 
    REG2MEM,
    MEM2REG
} MEM_TYPE;

typedef enum {
    EQ,
    NE,
    GEZ,
    GTZ,
    LEZ,
    LTZ
} COMPARE_TYPE;

typedef enum {
    BYTE, // 1 byte
    HEX, // 2 bytes
    WORD // 4 bytes
} LOAD_SIZE;

typedef enum {
    SIGNED,
    UNSIGNED
} EXT_TYPE;

typedef struct {
    IssueType issue_type; // assign the instruction to coresponding issue queue
    logic dest_valid;
    logic [`ARF_INDEX_WIDTH-1: 0] dest;
    logic srcL_valid;
    logic [`ARF_INDEX_WIDTH-1: 0] srcL;
    logic srcR_valid;
    logic [`ARF_INDEX_WIDTH-1: 0] srcR;
    logic shamt_valid;
    logic [`SHAMT_WIDTH-1: 0] shamt;
    logic imm16_valid;
    logic [15: 0] imm16;
    logic imm26_valid;
    logic [25: 0] imm26; 
    SIMPLE_ALU_OP salu_op;
    COMPLEX_ALU_OP calu_op;
    logic slt_trans;
    SHIFT_TYPE shift_type;
    logic need_log; // whether a jump instruction need to log its PC+8
    MOVE_TYPE move_type;
    logic check_exp; // not used now
    COMPARE_TYPE comp_type;
    LOAD_SIZE load_size;
    EXT_TYPE ext_type;
    MEM_TYPE mem_type;
} InstructionInfo;

`endif