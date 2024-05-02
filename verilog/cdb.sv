
// The decoder, copied from p3/stage_id.sv without changes

`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

// Decode an instruction: generate useful datapath control signals by matching the RISC-V ISA
// This module is purely combinational
module cdb (
    input logic done_alu, 
    input logic done_mult0,
    input logic done_mult1,
    input logic done_load_store,
    input logic done_branch,
    input logic [2:0] cdb_tag_alu,
    input logic [2:0] cdb_tag_mult0,
    input logic [2:0] cdb_tag_mult1,
    input logic [2:0] cdb_tag_load_store,
    input logic [2:0] cdb_tag_branch,
    input EX_MEM_PACKET cdb_val_alu,
    input EX_MEM_PACKET cdb_val_mult0,
    input EX_MEM_PACKET cdb_val_mult1,
    input EX_MEM_PACKET cdb_val_load_store,
    input EX_MEM_PACKET cdb_val_branch,
    output logic [2:0] cdb_tag,
    output logic [`XLEN-1:0] cdb_value,
    output logic  cdb_clear_alu,
    output logic  cdb_clear_mult0,
    output logic  cdb_clear_mult1,
    output logic  cdb_clear_load_store,
    output logic  cdb_clear_branch,
    output logic valid_cdb_out
);
    logic illegal;
    // Note: I recommend using an IDE's code folding feature on this block
    always_comb begin
 // if (valid)
	cdb_clear_alu <= 0;
        cdb_clear_mult0 <= 0;
        cdb_clear_mult1 <= 0;
        cdb_clear_load_store <= 0;
       // valid_cdb_out = 0;
	if(done_load_store) begin
	    cdb_tag <= cdb_tag_load_store;
	    cdb_value <= cdb_val_load_store.alu_result;
	    cdb_clear_load_store <= 1; 
	    valid_cdb_out <= 1;
	    $display("LS DONE TAG = %d VAL=%d", cdb_tag_load_store, cdb_val_load_store.alu_result);   
	end else if (done_mult0) begin
            cdb_tag <= cdb_tag_mult0;
	    cdb_value  <= cdb_val_mult0.alu_result; 
            cdb_clear_mult0 <= 1;
            valid_cdb_out <= 1;
	    $display("MULT0 DONE TAG = %d VAL=%d", cdb_tag_mult0, cdb_val_mult0.alu_result);
	end
	else if (done_mult1) begin
            cdb_tag <= cdb_tag_mult1;
	    cdb_value  <= cdb_val_mult1.alu_result; 
            cdb_clear_mult1 <= 1;
            valid_cdb_out <= 1;
	    $display("MULT1 DONE TAG = %d VAL=%d", cdb_tag_mult1, cdb_val_mult1.alu_result);
	end
        else if (done_alu) begin
            cdb_tag <= cdb_tag_alu;
	    cdb_value  <= cdb_val_alu.alu_result;    
	    cdb_clear_alu <= 1;  
            valid_cdb_out <= 1;
	    $display("ALU DONE TAG = %d VAL=%d", cdb_tag_alu, cdb_val_alu.alu_result);      
	end
	else if (done_branch) begin
            cdb_tag <= cdb_tag_branch;
	    cdb_value  <= cdb_val_branch.alu_result;
            cdb_clear_branch <= 1;
            valid_cdb_out <= 1;
	    $display("BRANCH DONE TAG = %d VAL=%d", cdb_tag_branch, cdb_val_branch.alu_result);
	end
	
    end // always

endmodule // cdb
