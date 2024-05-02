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



// Conditional branch module: compute whether to take conditional branches
// This module is purely combinational



module stage_ls (
    input clock,
    input reset,
    input [`XLEN-1:0]           Dmem2proc_data,
    input ID_EX_PACKET 		id_ex_reg,
    input logic 			valid,
    input logic[2:0] 		ROB_num,
    output logic [1:0]          proc2Dmem_command,
    output MEM_SIZE             proc2Dmem_size,
    output logic [`XLEN-1:0]    proc2Dmem_addr,
    output logic [`XLEN-1:0]    proc2Dmem_data,
    output logic 			done,
	//output logic			busy,
    output logic[2:0]		cdb_tag,
    output EX_MEM_PACKET 	ex_packet
);

    logic [`XLEN-1:0] opa_mux_out, opb_mux_out, read_data, alu_res;
    logic take_conditional;
    assign ex_packet.alu_result = (id_ex_reg.rd_mem) ? read_data : alu_res; 
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
    	done                   <= 0;
    	cdb_tag                <= 0;

    // Break out the signed/unsigned bit and memory read/write size
    	ex_packet.rd_unsigned  <= 0; // 1 if unsigned, 0 if signed
    	ex_packet.mem_size     <= 0;

    // ultimate "take branch" signal:
    // unconditional, or conditional and the condition is true
    	ex_packet.take_branch <= 0;


    end else begin
	if(valid) begin
		ex_packet.NPC          <= id_ex_reg.NPC;
		ex_packet.rs2_value    <= id_ex_reg.rs2_value;
		ex_packet.rd_mem       <= id_ex_reg.rd_mem;
		ex_packet.wr_mem       <= id_ex_reg.wr_mem;
		ex_packet.dest_reg_idx <= id_ex_reg.dest_reg_idx;
		ex_packet.halt         <= id_ex_reg.halt;
		ex_packet.illegal      <= id_ex_reg.illegal;
		ex_packet.csr_op       <= id_ex_reg.csr_op;
		ex_packet.valid        <= id_ex_reg.valid;
		done                   <= 1'b1;
		cdb_tag                <= ROB_num;
	        proc2Dmem_data         <= id_ex_reg.rs2_value;
		proc2Dmem_addr         <= alu_res;

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
	$display("STAGE result: %d", ex_packet.alu_result);
	end else done <= 1'b0;
    end

end

always_comb begin
        read_data = Dmem2proc_data;
        if (id_ex_reg.inst.r.funct3[2]) begin
            // unsigned: zero-extend the data
            if (id_ex_reg.inst.r.funct3[1:0] == BYTE) begin
                read_data[`XLEN-1:8] = 0;
            end else if (id_ex_reg.inst.r.funct3[1:0] == HALF) begin
                read_data[`XLEN-1:16] = 0;
            end
        end else begin
            // signed: sign-extend the data
            if (id_ex_reg.inst.r.funct3[1:0] == BYTE) begin
                read_data[`XLEN-1:8] = {(`XLEN-8){Dmem2proc_data[7]}};
            end else if (id_ex_reg.inst.r.funct3[1:0] == HALF) begin
                read_data[`XLEN-1:16] = {(`XLEN-16){Dmem2proc_data[15]}};
            end
        end
    end


    // Instantiate the ALU
    alu alu_1 (
        // Inputs
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(id_ex_reg.alu_func),

        // Output
        .result(alu_res)
    );

    // Instantiate the conditional branch module
    conditional_branch conditional_branch_1 (
        // Inputs
        .func(id_ex_reg.inst.b.funct3), // instruction bits for which condition to check
        .rs1(id_ex_reg.rs1_value),
        .rs2(id_ex_reg.rs2_value),

        // Output
        .take(take_conditional)
    );
    
endmodule // stage_ex
