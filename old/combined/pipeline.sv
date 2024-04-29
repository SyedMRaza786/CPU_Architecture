/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline.sv                                         //
//                                                                     //
//  Description :  Top-level module of the verisimple pipeline;        //
//                 This instantiates and connects the 5 stages of the  //
//                 Verisimple pipeline together.                       //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"
typedef struct packed{

    logic            buffer_full,
    logic            buffer_completed,
    logic[3:0]       head,
    logic[3:0]       tail,
    logic[2:0]       opcodes[7:0],
    logic[4:0]       input_reg_1s[7:0],
    logic[4:0]       input_reg_2s[7:0],
    logic[4:0]       dest_regs[7:0],
    logic[4:0]       Rs[7:0],
    logic[31:0]      Vs[7:0]
} ROB

typedef struct packed{
    
    output logic[4:0]       busy_signal,
    output logic [2:0]      out_opcode[4:0],
    output logic[31:0]      T[4:0],
    output logic[31:0]      T1[4:0],
    output logic [31:0]     T2[4:0],
    output logic[31:0]      V1[4:0],
    output logic [31:0]     V2[4:0],
    output logic[31:0]      map_table[31:0]; 


} RS

module pipeline (
    input        clock,             // System clock
    input        reset,             // System reset
    input [3:0]  mem2proc_response, // Tag from memory about current request
    input [63:0] mem2proc_data,     // Data coming back from memory
    input [3:0]  mem2proc_tag,      // Tag from memory about current reply

    output logic [1:0]       proc2mem_command, // Command sent to memory
    output logic [`XLEN-1:0] proc2mem_addr,    // Address sent to memory
    output logic [63:0]      proc2mem_data,    // Data sent to memory
`ifndef CACHE_MODE // no longer sending size to memory
    output MEM_SIZE          proc2mem_size,    // Data size sent to memory
`endif

    // Note: these are assigned at the very bottom of the module
    output logic [3:0]       pipeline_completed_insts,
    output EXCEPTION_CODE    pipeline_error_status,
    output logic [4:0]       pipeline_commit_wr_idx,
    output logic [`XLEN-1:0] pipeline_commit_wr_data,
    output logic             pipeline_commit_wr_en,
    output logic [`XLEN-1:0] pipeline_commit_NPC,

    // Debug outputs: these signals are solely used for debugging in testbenches
    // Do not change for project 3
    // You should definitely change these for project 4
    // output logic [`XLEN-1:0] if_NPC_dbg,
    // output logic [31:0]      if_inst_dbg,
    // output logic             if_valid_dbg,
    // output logic [`XLEN-1:0] if_id_NPC_dbg,
    // output logic [31:0]      if_id_inst_dbg,
    // output logic             if_id_valid_dbg,
    // output logic [`XLEN-1:0] id_ex_NPC_dbg,
    // output logic [31:0]      id_ex_inst_dbg,
    // output logic             id_ex_valid_dbg,
    // output logic [`XLEN-1:0] ex_mem_NPC_dbg,
    // output logic [31:0]      ex_mem_inst_dbg,
    // output logic             ex_mem_valid_dbg,
    // output logic [`XLEN-1:0] mem_wb_NPC_dbg,
    // output logic [31:0]      mem_wb_inst_dbg,
    // output logic             mem_wb_valid_dbg
);

    //////////////////////////////////////////////////
    //                                              //
    //                Pipeline Wires                //
    //                                              //
    //////////////////////////////////////////////////
/*
    // Pipeline register enables
    logic if_id_enable, id_ex_enable, ex_mem_enable, mem_wb_enable;

    // Outputs from IF-Stage and IF/ID Pipeline Register
    logic [`XLEN-1:0] proc2Imem_addr;
    IF_ID_PACKET if_packet, if_id_reg;

    // Outputs from ID stage and ID/EX Pipeline Register
    ID_EX_PACKET id_packet, id_ex_reg;

    // Outputs from EX-Stage and EX/MEM Pipeline Register
    EX_MEM_PACKET ex_packet, ex_mem_reg;

    // Outputs from MEM-Stage and MEM/WB Pipeline Register
    MEM_WB_PACKET mem_packet, mem_wb_reg;

    // Outputs from MEM-Stage to memory
    logic [`XLEN-1:0] proc2Dmem_addr;
    logic [`XLEN-1:0] proc2Dmem_data;
    logic [1:0]       proc2Dmem_command;
    MEM_SIZE          proc2Dmem_size;

    // Outputs from WB-Stage (These loop back to the register file in ID)
    logic             wb_regfile_en;
    logic [4:0]       wb_regfile_idx;
    logic [`XLEN-1:0] wb_regfile_data;

    //////////////////////////////////////////////////
    //                                              //
    //                Memory Outputs                //
    //                                              //
    //////////////////////////////////////////////////

    // these signals go to and from the processor and memory
    // we give precedence to the mem stage over instruction fetch
    // note that there is no latency in project 3
    // but there will be a 100ns latency in project 4
*/
    ROB rob_table;

    rob rob_unit(.clock(clock), .reset(reset), .rob_initial_valid(rob_initial_valid), .valid(rob_valid), 
    .opcode(rob_opcode), input_reg_1(.input_1_rob), .input_reg_2(.input_2_rob), .dest_reg(dest_reg_rob), 
    .commit(commit_rob), .value(value_rob), .rob_table(rob_table), .out(rob_table))

    RS rs_table;
    rs rs_unit(.clock(clock), .reset(reset), .rs_valid(rs_valid), 
.opcode(rs_opcode), .ROB_number(rob_table.tail), .input_reg_1(rs_reg1), .input_reg_2(rs_reg2),
.dest_reg(rs_dest_reg), .done_signal(rs_done_signal), .value_1(rs_V1), .value_2(rs_V2), 
.rs_table(rs_table), .out(rs_table))


    always_comb begin
        if (proc2Dmem_command != BUS_NONE) begin // read or write DATA from memory
            proc2mem_command = proc2Dmem_command;
            proc2mem_addr    = proc2Dmem_addr;
`ifndef CACHE_MODE
            proc2mem_size    = proc2Dmem_size;  // size is never DOUBLE in project 3
`endif
        end else begin                          // read an INSTRUCTION from memory
            proc2mem_command = BUS_LOAD;
            proc2mem_addr    = proc2Imem_addr;
`ifndef CACHE_MODE
            proc2mem_size    = DOUBLE;          // instructions load a full memory line (64 bits)
`endif
        end
        proc2mem_data = {32'b0, proc2Dmem_data};
    end

    //////////////////////////////////////////////////
    //                                              //
    //               Pipeline Outputs               //
    //                                              //
    //////////////////////////////////////////////////
/*
    assign pipeline_completed_insts = {3'b0, mem_wb_reg.valid}; // commit one valid instruction
    assign pipeline_error_status = mem_wb_reg.illegal        ? ILLEGAL_INST :
                                   mem_wb_reg.halt           ? HALTED_ON_WFI :
                                   (mem2proc_response==4'h0) ? LOAD_ACCESS_FAULT : NO_ERROR;

    assign pipeline_commit_wr_en   = wb_regfile_en;
    assign pipeline_commit_wr_idx  = wb_regfile_idx;
    assign pipeline_commit_wr_data = wb_regfile_data;
    assign pipeline_commit_NPC     = mem_wb_reg.NPC;
*/
endmodule // pipeline
