/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  rob.sv                                              //
//                                                                     //
//  Description :                                                      //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`define XLEN  32
`define ALU 3'b001
`define LD  3'b010
`define ST  3'b011
`define FP  3'b100


module rob (
    input logic            clock,          // system clock
    input logic            reset,          // system reset
    input logic            valid,
    input logic            value_valid,
    input logic [2:0]      value_tag,
    input logic[2:0]       opcode,
    input logic [4:0]      input_reg_1,
    input logic[4:0]       input_reg_2, 
    input logic[4:0]       dest_reg, 
    input logic [31:0]     value,
    input ROB              rob_table,
    output ROB             out,
    output logic           retire_out,
    input logic            retire_in    
    /*
    output logic            buffer_full,
    output logic            buffer_completed,
    output logic[3:0]       head,
    output logic[3:0]       tail,
    output logic[2:0]       opcodes[7:0],
    output logic[4:0]       input_reg_1s[7:0],
    output logic[4:0]       input_reg_2s[7:0],
    output logic[4:0]       dest_regs[7:0],
    output logic[4:0]       Rs[7:0],
    output logic[31:0]      Vs[7:0]
    */
); 

    
    

    logic [2:0] temp_tail = 0;
    always_comb begin
/*
        out.buffer_full = rob_table.buffer_full;
        out.buffer_completed = rob_table.buffer_completed;
        out.head = rob_table.head;
        out.tail = rob_table.tail;
        out.opcodes = rob_table.opcodes;
        out.input_reg_1s = rob_table.input_reg_1s;
        out.input_reg_2s = rob_table.input_reg_2s;
        out.dest_regs = rob_table.dest_regs;
        out.Rs = rob_table.Rs;
        out.Vs = rob_table.Vs;
*/
        if(reset) begin
            out.head <= 0;
            out.tail <= 0;
            for(int i = 0; i < 8; i++) begin
             // value_1[i] <= 0;
            //  value_2[i] <= 0; 
               
              out.opcodes[i] <= 3'b0;
              out.input_reg_1s[i] <= 5'b0;
              out.input_reg_2s[i] <= 5'b0;
              out.Rs[i] <= 5'b0;
              out.Vs[i] <= 32'b0;
              out.buffer_full <= 0;
	      out.buffer_completed <= 0;
            end
            
            
	end else begin
            out = rob_table
            if(valid == 1) begin
                if(rob_table.head == 0 && rob_table.tail == 0) begin
                    out.head            <= 1;
                    out.tail            <= 1;
                    out.opcodes[0]      <= opcode;
                    out.input_reg_1s[0] <= input_reg_1;
                    out.input_reg_2s[0] <= input_reg_2;
                    out.Rs[0]           <= dest_reg;
                end else begin
                    if(rob_table.tail == 7) begin
			temp_tail = 1;
		    end else begin
                        temp_tail = rob_table.tail + 1;
		    end
                    out.opcodes[temp_tail] <= opcode;
                    out.input_reg_1s[temp_tail] <= input_reg_1;
                    out.input_reg_2s[temp_tail] <= input_reg_2;
                    out.Rs[temp_tail] <= dest_reg;
                    if(temp_tail == 7) begin
			if(rob_table.head == 1) begin
			    out.buffer_full <= 1;
                        end else begin
			    out.tail <= 1;
			end
                    end else begin
                        if(rob_table.head != (temp_tail + 1) begin
                            out.tail <= temp_tail;
                        end else begin
                            out.tail <= temp_tail;
			    out.buffer_full <= 1
			end
		    end
                end
            end

	    /* To be determined in meeting */
	    if (value_valid == 1) begin
		out.Vs [value_tag - 1] <= value;
		if(value_tag == rob_table.head) begin
		    retire_out <= 1;
		end
	    end
            if(retire_in == 1) begin
                out.opcodes[rob_table.head] <= 3'b0;
                out.input_reg_1s[rob_table.head] <= 5'b0;
                out.input_reg_2s[rob_table.head] <= 5'b0;
                out.Rs[rob_table.head] <= 5'b0;
                out.Vs[rob_table.head] <= 32'b0;
                out.buffer_full <= 0;
		if(rob_table.head == 7) begin
		    out.head <= 1;
		end else begin
		    out.head <= rob_table.head + 1;
		end
	    end


	    end
   end 
endmodule 
