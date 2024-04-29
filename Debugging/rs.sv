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



module rs (
    input logic            	clock,          // system clock
    input logic            	reset,          // system reset
    input logic            	rs_valid,
    input logic            	cdb_valid,
    input logic [`XLEN-1:0] cdb_value,
    input logic [3:0]      	cdb_tag,
    input logic [2:0]     	cdb_unit,       
    input logic [2:0]      	opcode,    
    input logic [3:0]      	ROB_number,
    input logic [4:0]      	input_reg_1,
    input logic[4:0]       	input_reg_2, 
    input logic[4:0]       	dest_reg,  
    input logic[4:0]       	done_signal,
    input logic [31:0]     	value_1,
    input logic[31:0]      	value_2,
    input RS 		   	rs_table,
    input logic            	ready_in_rob_valid,
    input logic [1:0]      	ready_in_rob_register,
    input logic [2:0]      	ready_rob_num, squash_index, rob_tail,
    input ID_EX_PACKET	   	id_packet,
    input logic[4:0] 		exec_busy, 
    input logic			squash,   

    input logic            	retire,
    input logic [4:0]      	retire_register,
    input logic [2:0]      	retire_rob_number,
    input INST             	inst,
    output RS		   	out,
    output logic[4:0]		exec_run    

/*
    output logic[4:0]       busy_signal,
    output logic [2:0]      out_opcode[4:0],
    output logic[31:0]      T[4:0],
    output logic[31:0]      T1[4:0],
    output logic [31:0]     T2[4:0],
    output logic[31:0]      V1[4:0],
    output logic [31:0]     V2[4:0]
*/
); 
    
    //logic[`XLEN-1:0] value_1, value_2; 
    //logic[31:0]      map_table[31:0];
    logic [2:0] try_code = `LD;
	
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
       out.busy_signal <= 5'b0;
/*
	out.busy_signal = rs_table.busy_signal ;
        out.out_opcode = rs_table.out_opcode ;
        out.T = rs_table.T ;
        out.T1 = rs_table.T1 ;
        out.T2 = rs_table.T2 ;
        out.V1 = rs_table.V1 ;
        out.V2= rs_table.V2 ;
        out.map_table = rs_table.map_table;
*/
        if(reset) begin
			exec_run = 5'b0;
            for(int i = 0; i < 5; i++) begin
             // value_1[i] <= 0;
            //  value_2[i] <= 0;  
              out.busy_signal[i] <= 3'b0;
              out.out_opcode[i] <= 0;
              out.T[i] <= 0;
              out.T1[i] <= 0;
              out.T2[i] <= 0;
              out.V1[i] <= 0;
              out.V2[i] <= 0;
              out.inst[i] <= 0;
            end
            for (int i = 0; i < 32; i++)  out.map_table[i] <= 0;
            
	end else begin
	    out = rs_table;
	    if(rs_valid) begin
		    out.map_table[dest_reg] <= ROB_number;
		    
		    if(opcode == 3'b000) begin
			    out.inst[0] <= inst;
			    out.busy_signal[0] <= 1;
			    out.out_opcode[0] <= opcode;
			    out.T[0] <= ROB_number;
			    if(rs_table.map_table[input_reg_1] == 0) begin
				    out.V1[0] <= value_1;
			    end
			    if(rs_table.map_table[input_reg_2] == 0) begin
				    out.V2[0] <= value_2;
			    end
			    out.T1[0] <= rs_table.map_table[input_reg_1];
			    out.T2[0] <= rs_table.map_table[input_reg_2];
			    out.id_packet[0] <= id_packet; 

			    if (rs_table.map_table[input_reg_1] == 0 &&
					rs_table.map_table[input_reg_2] == 0 &&
					exec_busy[0] == 0) begin
					exec_run[0] <= 1'b1;
			    end
				
		    end else if(opcode == 3'b011) begin
			    out.inst[1] <= inst;
			    out.busy_signal[1] <= 1;
			    out.out_opcode[1] <= opcode;
			    out.T[1] <= ROB_number;
			    if(rs_table.map_table[input_reg_1] == 0) begin
				out.V1[1] <= value_1;
			    end
			    if(rs_table.map_table[input_reg_2] == 0) begin
				out.V2[1] <= value_2;
			    end
			    out.T1[1] <= rs_table.map_table[input_reg_1];
			    out.T2[1] <= rs_table.map_table[input_reg_2];
			    out.id_packet[1] <= id_packet; 

				if (rs_table.map_table[input_reg_1] == 0 &&
					rs_table.map_table[input_reg_2] == 0 &&
					exec_busy[1] == 0) begin
					exec_run[1] <= 1'b1;
			    end

		    end else if(opcode == 3'b100) begin
                            out.inst[2] <= inst;
			    out.busy_signal[2] <= 1;
			    out.out_opcode[2] <= opcode;
			    out.T[2] <= ROB_number;
			    if(rs_table.map_table[input_reg_1] == 0) begin
				out.V1[2] <= value_1;
			    end
			    if(rs_table.map_table[input_reg_2] == 0) begin
				out.V2[2] <= value_2;
			    end
			    out.T1[2] <= rs_table.map_table[input_reg_1];
			    out.T2[2] <= rs_table.map_table[input_reg_2];
			    out.id_packet[2] <= id_packet; 

				if (rs_table.map_table[input_reg_1] == 0 &&
					rs_table.map_table[input_reg_2] == 0 &&
					exec_busy[2] == 0) begin
					exec_run[2] <= 1'b1;
			    end

		    end else if (opcode == 3'b001) begin
			    if(rs_table.busy_signal[3] == 0) begin
                                out.inst[3] <= inst;
				out.busy_signal[3] <= 1;
				out.out_opcode[3] <= opcode;
				out.T[3] <= ROB_number;
			    if(rs_table.map_table[input_reg_1] == 0) begin
				    out.V1[3] <= value_1;
				end
				if(rs_table.map_table[input_reg_2] == 0) begin
				    out.V2[3] <= value_2;
				end
				out.T1[3] <= rs_table.map_table[input_reg_1];
				out.T2[3] <= rs_table.map_table[input_reg_2];
		        out.id_packet[3] <= id_packet; 
				
				if (rs_table.map_table[input_reg_1] == 0 &&
					rs_table.map_table[input_reg_2] == 0 &&
					exec_busy[3] == 0) begin
					exec_run[3] <= 1'b1;
			    end
				
			    end else begin
                out.inst[4] <= inst;
				out.busy_signal[4] <= 1; 
			    out.out_opcode[4] <= opcode;
				out.T[4] <= ROB_number;
			    if(rs_table.map_table[input_reg_1] == 0) begin
				    out.V1[4] <= value_1;
				end
				if(rs_table.map_table[input_reg_2] == 0) begin
				    out.V2[4] <= value_2;
				end
				out.T1[4] <= rs_table.map_table[input_reg_1];
				out.T2[4] <= rs_table.map_table[input_reg_2];
			        out.id_packet[4] <= id_packet; 				
			    end

				if (rs_table.map_table[input_reg_1] == 0 &&
					rs_table.map_table[input_reg_2] == 0 &&
					exec_busy[4] == 0) begin
					exec_run[4] <= 1'b1;
			    end

		    end
		    

		    for (int i = 0; i <= 5; i++) begin
		        if (done_signal[i] == 1) begin
		            out.busy_signal[i] <= 0;
		            out.out_opcode[i] <= 0;
		            out.T[i] <= 0;
		            out.T1[i] <= 0;
		            out.T2[i] <= 0;
		            out.V1[i] <= 0;
		            out.V2[i] <= 0;
		        end //end if done signal
		    end // end for
	        end // if instruction valid
		if(ready_in_rob_valid) begin
		    if(rs_table.map_table[ready_in_rob_register] == {ready_rob_num, 1'b0}) begin
				out.map_table[ready_in_rob_register][0] <= 1;
		    end


		end // if ready in rob
        if(cdb_valid) begin
    		if(rs_table.T1[cdb_unit] == cdb_tag) begin
				out.V1[cdb_unit] <= cdb_value;
			end	else if(rs_table.T2[cdb_unit] == cdb_tag) begin
				out.V2[cdb_unit] <= cdb_value;
			end	
		end // if cdb valid
		if(retire) begin
			if(rs_table.map_table[retire_register][3:1] == retire_rob_number) begin
				out.map_table[retire_register] <= 4'b0;
			end

		end
	        if(squash) begin
			
			if(rob_tail > squash_index) begin
				for(int i = 0; i < 5; i++) begin
		   		    if(rs_table.T[i] <= squash_index && rs_table.T[i] > rob_tail) begin
				      out.map_table[rs_table.id_packet[i].dest_reg_idx] <= 0;
				      out.busy_signal[i] <= 3'b0;
				      out.out_opcode[i] <= 0;
				      out.T[i] <= 0;
				      out.T1[i] <= 0;
				      out.T2[i] <= 0;
				      out.V1[i] <= 0;
				      out.V2[i] <= 0;
				      out.inst[i] <= 0;

				    end
				end
			    
			end else begin
			    for(int i = 0; i < 5; i++) begin
		   		    if((rs_table.T[i] >= squash_index && rs_table.T[i] < 7) ||(rs_table.T[i] <= rob_tail)) begin
				      out.map_table[rs_table.id_packet[i].dest_reg_idx] <= 0;
				      out.busy_signal[i] <= 3'b0;
				      out.out_opcode[i] <= 0;
				      out.T[i] <= 0;
				      out.T1[i] <= 0;
				      out.T2[i] <= 0;
				      out.V1[i] <= 0;
				      out.V2[i] <= 0;
				      out.inst[i] <= 0;

				    end
				end
			end
		end
	
	    end
	end // if not reset
    
   //end //always

endmodule 
