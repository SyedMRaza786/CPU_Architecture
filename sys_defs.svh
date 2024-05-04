/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  sys_defs.svh                                        //
//                                                                     //
//  Description :  This file has the macro-defines for macros used in  //
//                 the pipeline design.                                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __SYS_DEFS_SVH__
`define __SYS_DEFS_SVH__

// all files should `include "sys_defs.svh" to at least define the timescale
`timescale 1ns/100ps

`define ROB_SZ_8

///////////////////////////////////
// ---- Starting Parameters ---- //
///////////////////////////////////

`define N 1

//////////////////////////////////////////////////////////
// -------------------- I$ D$ Mem --------------------- //
//////////////////////////////////////////////////////////

`define FU_OPCODE_BIT_WIDTH 3
`define ALU_FU_SELECT_BIT_WIDTH 3

`define REG_ADDR_BIT_WIDTH 5

//////////////////////////////////////////////////////////
// --------------------- EX Stage --------------------- //
//////////////////////////////////////////////////////////

`define MULT_STAGES 4
`define DW_SIZE ((`XLEN * 2))
`define BITS_PER_STAGE (`DW_SIZE / `MULT_STAGES)

//////////////////////////////////////////////////////////
// OOO Pipeline Components: Functional Units + RS + ROB //
//////////////////////////////////////////////////////////

`define RS_SIZE 6
`define TOTAL_NUM_FU 5

`ifdef ROB_SZ_8
`define ROB_SIZE 8
`endif
`ifdef ROB_SZ_16
`define ROB_SIZE 16
`endif

`define ROB_BIT_WIDTH ($clog2(`ROB_SIZE) + 1)

// MAP Table
`define TAG_SIZE 4

// @TODO: CDB: tag_bit_width == 4
`define CDB_TAG_BIT_WIDTH 4
`define CDB_OUT_PACKET_LEN (`XLEN + `CDB_TAG_BIT_WIDTH + `TOTAL_NUM_FU + `FU_OPCODE_BIT_WIDTH + 2)

// sizes
`define ROB_SZ xx
`define RS_SZ xx
`define PHYS_REG_SZ (32 + `ROB_SZ)

// worry about these later
`define BRANCH_PRED_SZ xx
`define LSQ_SZ xx

// functional units (you should decide if you want more or fewer types of FUs)
`define NUM_FU_ALU xx
`define NUM_FU_MULT xx
`define NUM_FU_LOAD xx
`define NUM_FU_STORE xx

///////////////////////////////
// ---- Basic Constants ---- //
///////////////////////////////

// NOTE: the global CLOCK_PERIOD is defined in the Makefile

// useful boolean single-bit definitions
`define FALSE 1'h0
`define TRUE  1'h1

// data length
`define XLEN 32

// the zero register
// In RISC-V, any read of this register returns zero and any writes are thrown away
`define ZERO_REG 5'd0

// Basic NOP instruction. Allows pipline registers to clearly be reset with
// an instruction that does nothing instead of Zero which is really an ADDI x0, x0, 0
`define NOP 32'h00000013

//////////////////////////////////
// ---- Memory Definitions ---- //
//////////////////////////////////

// Cache mode removes the byte-level interface from memory, so it always returns
// a double word. The original processor won't work with this defined. Your new
// processor will have to account for this effect on mem.
// Notably, you can no longer write data without first reading.
`define CACHE_MODE

// you are not allowed to change this definition for your final processor
// the project 3 processor has a massive boost in performance just from having no mem latency
// see if you can beat it's CPI in project 4 even with a 100ns latency!
// `define MEM_LATENCY_IN_CYCLES  0
`define MEM_LATENCY_IN_CYCLES (100.0/`CLOCK_PERIOD+0.49999)
// the 0.49999 is to force ceiling(100/period). The default behavior for
// float to integer conversion is rounding to nearest

// How many memory requests can be waiting at once
`define NUM_MEM_TAGS 15

`define MEM_SIZE_IN_BYTES (64*1024)
`define MEM_64BIT_LINES   (`MEM_SIZE_IN_BYTES/8)


typedef union packed {
    logic [7:0][7:0]  byte_level;
    logic [3:0][15:0] half_level;
    logic [1:0][31:0] word_level;
} EXAMPLE_CACHE_BLOCK;

typedef enum logic [1:0] {
    BYTE   = 2'h0,
    HALF   = 2'h1,
    WORD   = 2'h2,
    DOUBLE = 2'h3
} MEM_SIZE;

// Memory bus commands
typedef enum logic [1:0] {
    BUS_NONE   = 2'h0,
    BUS_LOAD   = 2'h1,
    BUS_STORE  = 2'h2
} BUS_COMMAND;





///////////////////////////////
// ---- Exception Codes ---- //
///////////////////////////////

/**
 * Exception codes for when something goes wrong in the processor.
 * Note that we use HALTED_ON_WFI to signify the end of computation.
 * It's original meaning is to 'Wait For an Interrupt', but we generally
 * ignore interrupts in 470
 *
 * This mostly follows the RISC-V Privileged spec
 * except a few add-ons for our infrastructure
 * The majority of them won't be used, but it's good to know what they are
 */

typedef enum logic [3:0] {
    INST_ADDR_MISALIGN  = 4'h0,
    INST_ACCESS_FAULT   = 4'h1,
    ILLEGAL_INST        = 4'h2,
    BREAKPOINT          = 4'h3,
    LOAD_ADDR_MISALIGN  = 4'h4,
    LOAD_ACCESS_FAULT   = 4'h5,
    STORE_ADDR_MISALIGN = 4'h6,
    STORE_ACCESS_FAULT  = 4'h7,
    ECALL_U_MODE        = 4'h8,
    ECALL_S_MODE        = 4'h9,
    NO_ERROR            = 4'ha, // a reserved code that we use to signal no errors
    ECALL_M_MODE        = 4'hb,
    INST_PAGE_FAULT     = 4'hc,
    LOAD_PAGE_FAULT     = 4'hd,
    HALTED_ON_WFI       = 4'he, // 'Wait For Interrupt'. In 470, signifies the end of computation
    STORE_PAGE_FAULT    = 4'hf
} EXCEPTION_CODE;

///////////////////////////////////
// ---- Instruction Typedef ---- //
///////////////////////////////////

// from the RISC-V ISA spec
typedef union packed {
    logic [31:0] inst;
    struct packed {
        logic [6:0] funct7;
        logic [4:0] rs2; // source register 2
        logic [4:0] rs1; // source register 1
        logic [2:0] funct3;
        logic [4:0] rd; // destination register
        logic [6:0] opcode;
    } r; // register-to-register instructions
    struct packed {
        logic [11:0] imm; // immediate value for calculating address
        logic [4:0]  rs1; // source register 1 (used as address base)
        logic [2:0]  funct3;
        logic [4:0]  rd;  // destination register
        logic [6:0]  opcode;
    } i; // immediate or load instructions
    struct packed {
        logic [6:0] off; // offset[11:5] for calculating address
        logic [4:0] rs2; // source register 2
        logic [4:0] rs1; // source register 1 (used as address base)
        logic [2:0] funct3;
        logic [4:0] set; // offset[4:0] for calculating address
        logic [6:0] opcode;
    } s; // store instructions
    struct packed {
        logic       of;  // offset[12]
        logic [5:0] s;   // offset[10:5]
        logic [4:0] rs2; // source register 2
        logic [4:0] rs1; // source register 1
        logic [2:0] funct3;
        logic [3:0] et;  // offset[4:1]
        logic       f;   // offset[11]
        logic [6:0] opcode;
    } b; // branch instructions
    struct packed {
        logic [19:0] imm; // immediate value
        logic [4:0]  rd; // destination register
        logic [6:0]  opcode;
    } u; // upper-immediate instructions
    struct packed {
        logic       of; // offset[20]
        logic [9:0] et; // offset[10:1]
        logic       s;  // offset[11]
        logic [7:0] f;  // offset[19:12]
        logic [4:0] rd; // destination register
        logic [6:0] opcode;
    } j;  // jump instructions

// extensions for other instruction types
`ifdef ATOMIC_EXT
    struct packed {
        logic [4:0] funct5;
        logic       aq;
        logic       rl;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] rd;
        logic [6:0] opcode;
    } a; // atomic instructions
`endif
`ifdef SYSTEM_EXT
    struct packed {
        logic [11:0] csr;
        logic [4:0]  rs1;
        logic [2:0]  funct3;
        logic [4:0]  rd;
        logic [6:0]  opcode;
    } sys; // system call instructions
`endif

} INST; // instruction typedef, this should cover all types of instructions


/////////////////////////////////////////////////
// ---------- FUNCTIONAL UNITS / EX ---------- //
/////////////////////////////////////////////////

typedef enum logic [`ALU_FU_SELECT_BIT_WIDTH-1:0] {
    ALU_FU = 3'b001,
    MULT0_FU  = 3'b010,
    LS_FU  = 3'b011,
    BR_FU  = 3'b100,
    UNKNOWN_FU = 3'b000,
    MULT1_FU = 3'b101
} Opcode;

typedef struct {
    int opcode;
    int idx;
} OperationType;

// IMPORTANT!!! THE ORDER OF DECLARATION MATTERS FOR THIS AND @operationDetails
typedef enum {
   UNKNOWN,
   ALU,
   MULT0,
   LS,
   BR,
   MULT1
} OperationCode;

// @TODO: Decoder
// IMPORTANT!!! THE ORDER OF DECLARATION MATTERS FOR THIS AND @operationDetails
const OperationType funcUnits[6] = '{
   '{0, 0}, // Unknown
   '{1, 1}, // ALU
   '{2, 4}, // MULT0
   '{3, 2}, // LS
   '{4, 3}, // BR
   '{5, 5} // MULT1
};


////////////////////////////////////////
// ---- Datapath Control Signals ---- //
////////////////////////////////////////

// ALU opA input mux selects
typedef enum logic [1:0] {
    OPA_IS_RS1  = 2'h0,
    OPA_IS_NPC  = 2'h1,
    OPA_IS_PC   = 2'h2,
    OPA_IS_ZERO = 2'h3
} ALU_OPA_SELECT;

// ALU opB input mux selects
typedef enum logic [3:0] {
    OPB_IS_RS2    = 4'h0,
    OPB_IS_I_IMM  = 4'h1,
    OPB_IS_S_IMM  = 4'h2,
    OPB_IS_B_IMM  = 4'h3,
    OPB_IS_U_IMM  = 4'h4,
    OPB_IS_J_IMM  = 4'h5
} ALU_OPB_SELECT;

// ALU function code input
// probably want to leave these alone
typedef enum logic [4:0] {
    ALU_ADD     = 5'h00,
    ALU_SUB     = 5'h01,
    ALU_SLT     = 5'h02,
    ALU_SLTU    = 5'h03,
    ALU_AND     = 5'h04,
    ALU_OR      = 5'h05,
    ALU_XOR     = 5'h06,
    ALU_SLL     = 5'h07,
    ALU_SRL     = 5'h08,
    ALU_SRA     = 5'h09,
    ALU_MUL     = 5'h0a, // Mult FU
    ALU_MULH    = 5'h0b, // Mult FU
    ALU_MULHSU  = 5'h0c, // Mult FU
    ALU_MULHU   = 5'h0d, // Mult FU
    ALU_DIV     = 5'h0e, // unused
    ALU_DIVU    = 5'h0f, // unused
    ALU_REM     = 5'h10, // unused
    ALU_REMU    = 5'h11  // unused
} ALU_FUNC;

////////////////////////////////
// ---- Datapath Packets ---- //
////////////////////////////////

/**
 * Packets are used to move many variables between modules with
 * just one datatype, but can be cumbersome in some circumstances.
 *
 * Define new ones in project 4 at your own discretion
 */

/**
 * IF_ID Packet:
 * Data exchanged from the IF to the ID stage
 */
typedef struct packed {
    INST              inst;
    logic [`XLEN-1:0] PC;
    logic [`XLEN-1:0] NPC; // PC + 4
    logic             valid;
} IF_ID_PACKET;

/**
 * ID_EX Packet:
 * Data exchanged from the ID to the EX stage
 */
typedef struct packed {
    INST              inst;
    logic [`XLEN-1:0] PC;
    logic [`XLEN-1:0] NPC; // PC + 4

    logic [`XLEN-1:0] rs1_value; // reg A value
    logic [`XLEN-1:0] rs2_value; // reg B value

    ALU_OPA_SELECT opa_select; // ALU opa mux select (ALU_OPA_xxx *)
    ALU_OPB_SELECT opb_select; // ALU opb mux select (ALU_OPB_xxx *)

    logic [4:0] dest_reg_idx;  // destination (writeback) register index
    ALU_FUNC    alu_func;      // ALU function select (ALU_xxx *)
    logic       rd_mem;        // Does inst read memory?
    logic       wr_mem;        // Does inst write memory?
    logic       cond_branch;   // Is inst a conditional branch?
    logic       uncond_branch; // Is inst an unconditional branch?
    logic       halt;          // Is this a halt?
    logic       illegal;       // Is this instruction illegal?
    logic       csr_op;        // Is this a CSR operation? (we use this to get return code)

    logic       valid;
} ID_EX_PACKET;


typedef struct {
    logic                           done;
    logic [`CDB_TAG_BIT_WIDTH-1:0]  tag;
} ex_packet_out;


/**
 * EX_MEM Packet:
 * Data exchanged from the EX to the MEM stage
 */
typedef struct packed {
    logic [`XLEN-1:0] alu_result;
    logic [`XLEN-1:0] NPC;

    logic             take_branch; // Is this a taken branch?
    // Pass-through from decode stage
    logic [`XLEN-1:0] rs2_value;
    logic             rd_mem;
    logic             wr_mem;
    logic [4:0]       dest_reg_idx;
    logic             halt;
    logic             illegal;
    logic             csr_op;
    logic             rd_unsigned; // Whether proc2Dmem_data is signed or unsigned
    MEM_SIZE          mem_size;
    logic             valid;
} EX_MEM_PACKET;

/**
 * MEM_WB Packet:
 * Data exchanged from the MEM to the WB stage
 *
 * Does not include data sent from the MEM stage to memory
 */
typedef struct packed {
    logic [`XLEN-1:0] result;
    logic [`XLEN-1:0] NPC;
    logic [4:0]       dest_reg_idx; // writeback destination (ZERO_REG if no writeback)
    logic             take_branch;
    logic             halt;    // not used by wb stage
    logic             illegal; // not used by wb stage
    logic             valid;
} MEM_WB_PACKET;

/**
 * No WB output packet as it would be more cumbersome than useful
 */
typedef struct {
    logic [`RS_SIZE-1:0]                busy_signal;
    logic [`FU_OPCODE_BIT_WIDTH-1:0]    out_opcode[`RS_SIZE-1:0];
    logic [`ROB_BIT_WIDTH-1:0]          T[`RS_SIZE-1:0]; // 4 x 6 bits
    logic [`ROB_BIT_WIDTH-1:0]          T1[`RS_SIZE-1:0];
    logic [`ROB_BIT_WIDTH-1:0]          T2[`RS_SIZE-1:0];
    logic [`XLEN-1:0]                   V1[`RS_SIZE-1:0]; // 32 x 6 bits
    logic [`XLEN-1:0]                   V2[`RS_SIZE-1:0];

    logic [`REG_ADDR_BIT_WIDTH-1:0]    map_table[`XLEN-1:0]; // 5 x 32 bits
    ID_EX_PACKET                       id_packet[`RS_SIZE-1:0];
    INST             inst[`RS_SIZE-1:0];
} RS;
// logic width rows



typedef struct {
    logic                           buffer_full;
    logic                           buffer_completed;
    logic [`ROB_BIT_WIDTH-1:0]       head;
    logic [`ROB_BIT_WIDTH-1:0]       tail;
    logic [2:0]                      opcodes[`ROB_SIZE-1:0];
    logic [`REG_ADDR_BIT_WIDTH-1:0]           input_reg_1s[`ROB_SIZE-1:0];
    logic [`REG_ADDR_BIT_WIDTH-1:0]           input_reg_2s[`ROB_SIZE-1:0];
    logic [`REG_ADDR_BIT_WIDTH-1:0]           dest_regs[`ROB_SIZE-1:0];
    logic [`XLEN-1:0]                Rs[`ROB_SIZE-1:0];
    logic [`XLEN-1:0]      Vs[`ROB_SIZE-1:0];
    ID_EX_PACKET     id_packet[`ROB_SIZE-1:0];
} ROB;


typedef struct packed {
	logic [`XLEN-1:0]		            NPC;
	logic [`XLEN-1:0]		            PC;
	logic					               fu_done;
	logic [`REG_ADDR_BIT_WIDTH-1:0]  dest_reg_idx;
	logic [`XLEN-1:0]		            value;
   logic [`CDB_TAG_BIT_WIDTH-1:0]        value_tag;
   Opcode                        opcode;
   logic [`REG_ADDR_BIT_WIDTH-1:0]  rs1_in;
   logic [`REG_ADDR_BIT_WIDTH-1:0]  rs2_in;
   logic					               value_valid;
   logic                            is_mult;
	logic				                  is_load_store;
	logic 					            is_branch;
	logic [`XLEN-1:0]	               branch_addr;
	logic					               take_branch;
   logic                            squash;
   logic [`ROB_BIT_WIDTH-1:0]       squash_idx;
	logic				                  halt;
} ROB_ENTRY;



typedef enum logic [2:0] {
    CDB_ALU = 3'b001,
    CDB_MULT0 = 3'b010,
    CDB_MULT1 = 3'b011,
    CDB_LOAD_STORE = 3'b100,
    CDB_BRANCH = 3'b101
} CDBControl;


typedef struct packed {
   logic                            valid;
   logic                            clear;             // 1 bit
   logic [`FU_OPCODE_BIT_WIDTH-1:0] fu;
   Opcode                           fu_opcode;
   logic [`XLEN-1:0]                value;        // XLEN bits
   logic [`CDB_TAG_BIT_WIDTH-1:0]   tag;
} CDB_OUTPUT;

typedef struct packed {
   logic done;
   // logic busy;
   logic exec;
   logic [`CDB_TAG_BIT_WIDTH-1:0] tag;
   logic [`XLEN-1:0] result;
} EX_CDB_PACKET;

typedef struct packed {
   logic done;
   logic busy;
   logic exec;
   logic [`CDB_TAG_BIT_WIDTH-1:0] tag;
   logic [`XLEN-1:0] result;
} EX_RS_PACKET;

typedef struct packed {
   logic 			exec_done;
   logic 			valid;
   logic [`CDB_TAG_BIT_WIDTH-1:0] tag;
   logic [`XLEN-1:0] 		result;  // Field from EX_MEM_PACKET
   //    logic [`XLEN-1:0] mem_result; // Field from MEM_WB_PACKET
   // } value;
   Opcode     			fu_opcode;
   logic 			clear;
} RS_CDB_PACKET;


// typedef struct packed {
//    logic exec_done;
//    logic valid;
   
//    logic [`CDB_TAG_BIT_WIDTH-1:0] tag;
//    logic [`XLEN-1:0] result;  // Field from EX_MEM_PACKET
//    //    logic [`XLEN-1:0] mem_result; // Field from MEM_WB_PACKET
//    // } value;
//    Opcode                             fu_opcode;
//    logic clear;
// } CDB_ENTRY_PACKET_IN;

// typedef struct packed {
//     CDB_ENTRY_PACKET_IN alu0;
//     CDB_ENTRY_PACKET_IN mult0;
//     CDB_ENTRY_PACKET_IN mult1;
//     CDB_ENTRY_PACKET_IN ls;
//     CDB_ENTRY_PACKET_IN br;
// } CDB_ENTRY;


`endif // __SYS_DEFS_SVH__
