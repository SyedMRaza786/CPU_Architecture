/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  stage_id.sv                                         //
//                                                                     //
//  Description :  instruction decode (ID) stage of the pipeline;      //
//                 decode the instruction fetch register operands, and //
//                 compute immediate operand (if applicable)           //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

// Decode an instruction: generate useful datapath control signals by matching the RISC-V ISA
// This module is purely combinational

module stage_id (
    input              clock,           // system clock
    input              reset,           // system reset
    input IF_ID_PACKET if_id_reg,
    input              wb_regfile_en,   // Reg write enable from WB Stage
    input [4:0]        wb_regfile_idx,  // Reg write index from WB Stage
    input [`XLEN-1:0]  wb_regfile_data, // Reg write data from WB Stage


    output ID_EX_PACKET id_packet
);

    assign id_packet.inst = if_id_reg.inst;
    assign id_packet.PC   = if_id_reg.PC;
    assign id_packet.NPC  = if_id_reg.NPC;

    // For counting valid instructions executed
    // and making the fetch stage die on halts/keeping track of when
    // to allow the next instruction out of fetch
    // 0 for HALT and illegal instructions (end processor on halt)
    assign id_packet.valid = if_id_reg.valid & ~id_packet.illegal;

    logic has_dest_reg;
    assign id_packet.dest_reg_idx = (has_dest_reg) ? if_id_reg.inst.r.rd : `ZERO_REG;

    // Instantiate the register file
    regfile regfile_0 (
        .clock  (clock),
        .read_idx_1 (if_id_reg.inst.r.rs1),
        .read_idx_2 (if_id_reg.inst.r.rs2),
        .write_en   (wb_regfile_en),
        .write_idx  (wb_regfile_idx),
        .write_data (wb_regfile_data),

        .read_out_1 (id_packet.rs1_value),
        .read_out_2 (id_packet.rs2_value)

    );

    // Instantiate the instruction decoder
    decoder decoder_0 (
        // Inputs
        .inst  (if_id_reg.inst),
        .valid (if_id_reg.valid),

        // Outputs
        .opa_select    (id_packet.opa_select),
        .opb_select    (id_packet.opb_select),
        .alu_func      (id_packet.alu_func),
        .has_dest      (has_dest_reg),
        .rd_mem        (id_packet.rd_mem),
        .wr_mem        (id_packet.wr_mem),
        .cond_branch   (id_packet.cond_branch),
        .uncond_branch (id_packet.uncond_branch),
        .csr_op        (id_packet.csr_op),
        .halt          (id_packet.halt),
        .illegal       (id_packet.illegal)
    );

endmodule // stage_id
