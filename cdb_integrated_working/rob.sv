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
    input logic            squash,
    input logic [2:0]      squash_index,
    output ROB             out,
    output logic           retire_out, writeback_valid,
    input logic            retire_in,
    input ID_EX_PACKET     id_packet    
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

    
    

    logic [2:0] temp_tail;
    always_ff @(posedge clock) begin
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
              out.id_packet[i] <= 0;
	      temp_tail = 0;
            end
            
            
	end else begin
            out = rob_table;
            
            if(valid == 1) begin
                if(rob_table.head == 0 && rob_table.tail == 0) begin
                    out.head            <= 1;
                    out.tail            <= 1;
                    out.opcodes[0]      <= opcode;
                    out.input_reg_1s[0] <= input_reg_1;
                    out.input_reg_2s[0] <= input_reg_2;
                    out.Rs[0]           <= dest_reg;
		    out.id_packet[0]    <= id_packet;
                end else begin
                    if(rob_table.tail == 7) begin
			    out.opcodes[0] <= opcode;
		            out.input_reg_1s[0] <= input_reg_1;
		            out.input_reg_2s[0] <= input_reg_2;
		            out.Rs[0] <= dest_reg;
			    out.id_packet[0]    <= id_packet;
			    
		            out.tail <= 1;
		    end else begin
			    out.opcodes[rob_table.tail] <= opcode;
		            out.input_reg_1s[rob_table.tail] <= input_reg_1;
		            out.input_reg_2s[rob_table.tail] <= input_reg_2;
		            out.Rs[rob_table.tail] <= dest_reg;
			    out.id_packet[rob_table.tail]    <= id_packet;
                            if(rob_table.tail == 6) begin
				if(rob_table.head == 1) begin
				    out.buffer_full <= 1;
                                    out.tail <= 7;
		                end else begin
				    out.tail <= 7;
				end
		            end else begin
		                if(rob_table.head != (rob_table.tail + 2)) begin
		                    out.tail <= rob_table.tail+1;
				    
		                end else begin
		                    out.tail <= rob_table.tail + 1;
				    
				    out.buffer_full <= 1;
				end
			    end
		    end
                    
                    
                end
            end

	    /* To be determined in meeting */
	    if (value_valid == 1) begin
		out.Vs [value_tag - 1] <= value;
		if(value_tag == rob_table.head) begin
		    retire_out <= 1;
                    if(rob_table.Rs[rob_table.head] != 0) begin
			writeback_valid <= 1;
		    end else writeback_valid <= 0;
		end
	    end
            if(retire_in == 1) begin
                out.opcodes[rob_table.head] <= 3'b0;
                out.input_reg_1s[rob_table.head] <= 5'b0;
                out.input_reg_2s[rob_table.head] <= 5'b0;
                out.Rs[rob_table.head] <= 5'b0;
                out.Vs[rob_table.head] <= 32'b0;
                out.buffer_full <= 0;
		out.id_packet[rob_table.head]    <= 0;
		if(rob_table.head == 7) begin
		    out.head <= 1;
		end else begin
		    out.head <= rob_table.head + 1;
		end
	    end
            if(squash) begin
		if(rob_table.tail > squash_index) begin
		    for (int i = squash_index+1; i < rob_table.tail; i++) begin
			out.tail <= squash_index;
			out.opcodes[i] <= 3'b0;
              		out.input_reg_1s[i] <= 5'b0;
              		out.input_reg_2s[i] <= 5'b0;
              		out.Rs[i] <= 5'b0;
              		out.Vs[i] <= 32'b0;
              		out.buffer_full <= 0;
	      		out.buffer_completed <= 0;
              		out.id_packet[i] <= 0;

		    end
		end else begin
		    for (int i = squash_index+1; i < 8; i++) begin
			out.tail <= squash_index;
			out.opcodes[i] <= 3'b0;
              		out.input_reg_1s[i] <= 5'b0;
              		out.input_reg_2s[i] <= 5'b0;
              		out.Rs[i] <= 5'b0;
              		out.Vs[i] <= 32'b0;
              		out.buffer_full <= 0;
	      		out.buffer_completed <= 0;
              		out.id_packet[i] <= 0;

		    end
		    for (int j = 0; j < rob_table.tail; j++) begin
			out.tail <= squash_index;
			out.opcodes[j] <= 3'b0;
              		out.input_reg_1s[j] <= 5'b0;
              		out.input_reg_2s[j] <= 5'b0;
              		out.Rs[j] <= 5'b0;
              		out.Vs[j] <= 32'b0;
              		out.buffer_full <= 0;
	      		out.buffer_completed <= 0;
              		out.id_packet[j] <= 0;

		    end
		end
	
	    end


	    end
        $display("ROB Contents:");
        $display("Head: %d, Tail: %d, Buffer Full: %d, Buffer Completed: %d", out.head, out.tail, out.buffer_full, out.buffer_completed);
        for (int i = 0; i < 8; i++) begin
            $display("Entry %d:", i);
            $display("  Op: %b, I1: %d, I2: %d, D: %d, V: %d", out.opcodes[i], out.input_reg_1s[i], out.input_reg_2s[i], out.Rs[i], out.Vs[i]);
            //$display("  ID_EX_PACKET: %p", out.id_packet[i]);
        end
        $display("------------------------");
   end //ALWAYS
endmodule 
