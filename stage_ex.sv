/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  stage_ex.sv                                         //
//                                                                     //
//  Description :  instruction execute (EX) stage of the pipeline;     //
//                 given the instruction command code CMD, select the  //
//                 proper input A and B for the ALU, compute the       //
//                 result, and compute the condition for branches, and //
//                 pass all the results down the pipeline.             //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

// ALU: computes the result of FUNC applied with operands A and B
// This module is purely combinational
module alu (
    input [`XLEN-1:0] opa,
    input [`XLEN-1:0] opb,
    ALU_FUNC          func,

    output logic [`XLEN-1:0] result
);

    logic signed [`XLEN-1:0]   signed_opa, signed_opb;
    logic signed [2*`XLEN-1:0] signed_mul, mixed_mul;
    logic        [2*`XLEN-1:0] unsigned_mul;

    assign signed_opa   = opa;
    assign signed_opb   = opb;

    // We let verilog do the full 32-bit multiplication for us.
    // This gives a large clock period.
    // You will replace this with your pipelined multiplier in project 4.
    assign signed_mul   = signed_opa * signed_opb;
    assign unsigned_mul = opa * opb;
    assign mixed_mul    = signed_opa * opb;

    always_comb begin
        case (func)
            ALU_ADD:    result = opa + opb;
            ALU_SUB:    result = opa - opb;
            ALU_AND:    result = opa & opb;
            ALU_SLT:    result = signed_opa < signed_opb;
            ALU_SLTU:   result = opa < opb;
            ALU_OR:     result = opa | opb;
            ALU_XOR:    result = opa ^ opb;
            ALU_SRL:    result = opa >> opb[4:0];
            ALU_SLL:    result = opa << opb[4:0];
            ALU_SRA:    result = signed_opa >>> opb[4:0]; // arithmetic from logical shift
            ALU_MUL:    result = signed_mul[`XLEN-1:0];
            ALU_MULH:   result = signed_mul[2*`XLEN-1:`XLEN];
            ALU_MULHSU: result = mixed_mul[2*`XLEN-1:`XLEN];
            ALU_MULHU:  result = unsigned_mul[2*`XLEN-1:`XLEN];

            default:    result = `XLEN'hfacebeec;  // here to prevent latches
        endcase
    end

endmodule // alu


// Conditional branch module: compute whether to take conditional branches
// This module is purely combinational
module conditional_branch (
    input [2:0]       func, // Specifies which condition to check
    input [`XLEN-1:0] rs1,  // Value to check against condition
    input [`XLEN-1:0] rs2,

    output logic take // True/False condition result
);

    logic signed [`XLEN-1:0] signed_rs1, signed_rs2;
    assign signed_rs1 = rs1;
    assign signed_rs2 = rs2;
    always_comb begin
        case (func)
            3'b000:  take = signed_rs1 == signed_rs2; // BEQ
            3'b001:  take = signed_rs1 != signed_rs2; // BNE
            3'b100:  take = signed_rs1 < signed_rs2;  // BLT
            3'b101:  take = signed_rs1 >= signed_rs2; // BGE
            3'b110:  take = rs1 < rs2;                // BLTU
            3'b111:  take = rs1 >= rs2;               // BGEU
            default: take = `FALSE;
        endcase
    end

endmodule // conditional_branch


module stage_ex (
   input                   clock,
   input                   reset,
   input ID_EX_PACKET 		id_ex_reg,
	input logic 			   valid,
	input logic [`ROB_BIT_WIDTH-1:0] ROB_num,

	// output logic 			done,
	//output logic			busy,
	// output logic[2:0]		cdb_tag,
   output EX_CDB_PACKET    ex_cdb,
   output EX_MEM_PACKET 	ex_packet
);

   logic [`XLEN-1:0] opa_mux_out, opb_mux_out;
   logic take_conditional;
   ALU_FUNC alu_func;

// `ifdef DEBUG
   function string get_func_name(ALU_FUNC func);
      case (func)
         ALU_OR: return "ALU_OR";
         ALU_XOR: return "ALU_XOR";
         ALU_SLL: return "ALU_SLL";
         ALU_SRL: return "ALU_SRL";
         ALU_SRA: return "ALU_SRA";
         ALU_MUL: return "ALU_MUL";
         ALU_MULH: return "ALU_MULH";
         ALU_MULHSU: return "ALU_MULHSU";
         ALU_MULHU: return "ALU_MULHU";
         ALU_DIV: return "ALU_DIV";
         ALU_DIVU: return "ALU_DIVU";
         ALU_REM: return "ALU_REM";
         ALU_REMU: return "ALU_REMU";
         default: return "Unknown Function";
      endcase
   endfunction
// `endif

   always_ff @(posedge clock) begin
      if(reset) begin
      ex_packet.NPC          <= 0;
      ex_packet.rs2_value    <= 0;
      ex_packet.rd_mem       <= 0;
      ex_packet.wr_mem       <= 0;
      ex_packet.dest_reg_idx <= 0;
      ex_packet.halt         <= 0;
      ex_packet.illegal      <= 0;
      ex_packet.csr_op       <= 0;
      ex_packet.valid        <= 0;
      ex_cdb <= '{default: 0};
      // done                   <= 0;
      // cdb_tag                <= 0;

    // Break out the signed/unsigned bit and memory read/write size
    	ex_packet.rd_unsigned  <= 0; // 1 if unsigned, 0 if signed
    	ex_packet.mem_size     <= 0;

    // ultimate "take branch" signal:
    // unconditional, or conditional and the condition is true
    	ex_packet.take_branch <= 0;


    end else begin
	if(valid) begin
      display_id_ex_packet(id_ex_reg, ROB_num);
      // $display("   Stage_EX: ROB %d executing now", ROB_num);
		ex_packet.NPC          <= id_ex_reg.NPC;
		ex_packet.rs2_value    <= id_ex_reg.rs2_value;
		ex_packet.rd_mem       <= id_ex_reg.rd_mem;
		ex_packet.wr_mem       <= id_ex_reg.wr_mem;
		ex_packet.dest_reg_idx <= id_ex_reg.dest_reg_idx;
		ex_packet.halt         <= id_ex_reg.halt;
		ex_packet.illegal      <= id_ex_reg.illegal;
		ex_packet.csr_op       <= id_ex_reg.csr_op;
		ex_packet.valid        <= id_ex_reg.valid;
      ex_cdb.done             <= 1'b1;
      ex_cdb.tag <= ROB_num;
		// done                   <= 1'b1;
		// cdb_tag                <= ROB_num;

	    // Break out the signed/unsigned bit and memory read/write size
		ex_packet.rd_unsigned  <= id_ex_reg.inst.r.funct3[2]; // 1 if unsigned, 0 if signed
		ex_packet.mem_size     <= MEM_SIZE'(id_ex_reg.inst.r.funct3[1:0]);

	    // ultimate "take branch" signal:
	    // unconditional, or conditional and the condition is true
		ex_packet.take_branch <= id_ex_reg.uncond_branch || (id_ex_reg.cond_branch && take_conditional);

		case (id_ex_reg.opa_select)
		    OPA_IS_RS1:  opa_mux_out <= id_ex_reg.rs1_value;
		    OPA_IS_NPC:  opa_mux_out <= id_ex_reg.NPC;
		    OPA_IS_PC:   opa_mux_out <= id_ex_reg.PC;
		    OPA_IS_ZERO: opa_mux_out <= 0;
		    default:     opa_mux_out <= `XLEN'hdeadface; // dead face
		endcase

		case (id_ex_reg.opb_select)
		    OPB_IS_RS2:   opb_mux_out <= id_ex_reg.rs2_value;
		    OPB_IS_I_IMM: opb_mux_out <= `RV32_signext_Iimm(id_ex_reg.inst);
		    OPB_IS_S_IMM: opb_mux_out <= `RV32_signext_Simm(id_ex_reg.inst);
		    OPB_IS_B_IMM: opb_mux_out <= `RV32_signext_Bimm(id_ex_reg.inst);
		    OPB_IS_U_IMM: opb_mux_out <= `RV32_signext_Uimm(id_ex_reg.inst);
		    OPB_IS_J_IMM: opb_mux_out <= `RV32_signext_Jimm(id_ex_reg.inst);
		    default:      opb_mux_out <= `XLEN'hfacefeed; // face feed
		endcase
      end else ex_cdb.done <= 1'b0;
    end

end


    // Instantiate the ALU
    alu alu_0 (
        // Inputs
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(id_ex_reg.alu_func),

        // Output
        .result(ex_packet.alu_result)
    );

    // Instantiate the conditional branch module
    conditional_branch conditional_branch_0 (
        // Inputs
        .func(id_ex_reg.inst.b.funct3), // instruction bits for which condition to check
        .rs1(id_ex_reg.rs1_value),
        .rs2(id_ex_reg.rs2_value),

        // Output
        .take(take_conditional)
    );

    task display_id_ex_packet(ID_EX_PACKET id_ex_reg, rob_num);
        $display("  ROB %2d is currently executing, ID_EX_PACKET:", rob_num);
        $display("      Instruction: %b", id_ex_reg.inst);
        $display("      PC: %4d                  NPC (PC+4): %4d", id_ex_reg.PC, id_ex_reg.NPC);
        $display("      Dest Reg Index: %4d      RS1 Value: %4d      RS2 Value: %4d", id_ex_reg.dest_reg_idx, id_ex_reg.rs1_value, id_ex_reg.rs2_value);
        $display("      ALU Function: %s", get_func_name(id_ex_reg.alu_func));
        $display("      Read Memory: %0d         Write Memory: %0d", id_ex_reg.rd_mem, id_ex_reg.wr_mem);
        $display("      Conditional Branch: %0d  Unconditional Branch: %0d", id_ex_reg.cond_branch, id_ex_reg.uncond_branch);
        $display("      Halt: %0d, Illegal Instruction: %0d, CSR Operation: %0d", id_ex_reg.halt, id_ex_reg.illegal,  id_ex_reg.csr_op);
        $display("      Valid: %0d", id_ex_reg.valid);
    endtask

    
endmodule // stage_ex
