/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  RS.sv                                               //
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
    input logic[2:0]       opcode,
    input logic [4:0]      input_reg_1,
    input logic[4:0]       input_reg_2, 
    input logic[4:0]       dest_reg,
    input logic            commit, 
    input logic [31:0]     value,

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
); 

    
    
    
/*
    regfile regfile_0 (
        .clock  (clock),
        .read_idx_1 (input_reg_1),
        .read_idx_2 (input_reg_2),
        .write_en   (1'b0),
        .write_idx  (dest_reg),
        .write_data (`XLEN'b0),

        .read_out_1 (value_1),
        .read_out_2 (value_2)

    );
*/
    always_ff @(posedge clock) begin
        if(reset) begin
            head <= 0;
            tail <= 0;
            for(int i = 0; i < 8; i++) begin
             // value_1[i] <= 0;
            //  value_2[i] <= 0; 
               
              opcodes[i] <= 3'b0;
              input_reg_1s[i] <= 5'b0;
              input_reg_2s[i] <= 5'b0;
              Rs[i] <= 5'b0;
              Vs[i] <= 32'b0;
              buffer_full <= 0;
	      buffer_completed <= 0;
            end
            
            
	end else begin
	    if(valid == 1) begin
		if(head == 0 && tail == 0) begin
		    head            <= 1;
		    tail            <= 1;
		    opcodes[0]      <= opcode;
                    input_reg_1s[0] <= input_reg_1;
		    input_reg_2s[0] <= input_reg_2;
                    Rs[0]           <= dest_reg;
		end else begin
		    
                    opcodes[tail] <= opcode;
                    input_reg_1s[tail] <= input_reg_1;
		    input_reg_2s[tail] <= input_reg_2;
		    Rs[tail] <= dest_reg;
                    tail <= tail + 1;
		end
	    end
	    if(commit == 1) begin
		Vs[head] <= value;
		if(head == 8) begin
		    buffer_completed <= 1;
                    head <= 0;
		    tail <= 0;
		end
	    end
	    if(tail == 8) begin
		buffer_full <= 1;
	    end
	end
    
   end 

endmodule 
