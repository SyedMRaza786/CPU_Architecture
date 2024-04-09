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


module rs (
    input logic            clock,          // system clock
    input logic            reset,          // system reset
    input logic            rs_valid,       // only go to next PC when true
    input logic [2:0]      opcode,    // taken-branch signal
    input logic [31:0]     ROB_number,
    input logic [4:0]      input_reg_1,
    input logic[4:0]       input_reg_2, 
    input logic[4:0]       dest_reg,  
    input logic[4:0]       done_signal,
    input logic [31:0]     value_1,
    input logic[31:0]      value_2,
    input RS 		   rs_table,
    output RS		   out    

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


    always @(rs_valid) begin
        assign out.busy_signal = rs_table.busy_signal ;
        assign out.out_opcode = rs_table.out_opcode ;
        assign out.T = rs_table.T ;
        assign out.T1 = rs_table.T1 ;
        assign out.T2 = rs_table.T2 ;
        assign out.V1 = rs_table.V1 ;
        assign out.V2= rs_table.V2 ;
        assign out.map_table = rs_table.map_table;
    end

    always_ff @(posedge clock) begin
        if(reset) begin
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
            end
            for (int i = 0; i < 32; i++)  map_table[i] <= 0;
            
	end else begin
	    out.map_table[dest_reg] <= ROB_number;
	    
	    if(opcode == `ALU) begin
			
		    out.busy_signal[0] <= 1;
		    out.out_opcode[0] <= opcode;
		    out.T[0] <= ROB_number;
		    if(out.map_table[input_reg_1] == 0) begin
			    out.V1[0] <= value_1;
		    end
		    if(out.map_table[input_reg_2] == 0) begin
			    out.V2[0] <= value_2;
		    end
		    out.T1[0] <= out.map_table[input_reg_1];
		    out.T2[0] <= out.map_table[input_reg_2];
	    end else if(opcode == `LD) begin
		    out.busy_signal[1] <= 1;
		    out.out_opcode[1] <= opcode;
		    out.T[1] <= ROB_number;
		    if(out.map_table[input_reg_1] == 0) begin
			out.V1[1] <= value_1;
		    end
		    if(out.map_table[input_reg_2] == 0) begin
			out.V2[1] <= value_2;
		    end
		    out.T1[1] <= out.map_table[input_reg_1];
		    out.T2[1] <= out.map_table[input_reg_2];
	    end else if(opcode == `ST) begin

		    out.busy_signal[2] <= 1;
		    out.out_opcode[2] <= opcode;
		    out.T[2] <= ROB_number;
		    if(out.map_table[input_reg_1] == 0) begin
			out.V1[2] <= value_1;
		    end
		    if(out.map_table[input_reg_2] == 0) begin
			out.V2[2] <= value_2;
		    end
		    out.T1[2] <= out.map_table[input_reg_1];
		    out.T2[2] <= out.map_table[input_reg_2];
	    end else if (opcode == `FP) begin
		    if(out.busy_signal[3] == 0) begin
			    out.busy_signal[3] <= 1;
		        out.out_opcode[3] <= opcode;
		        out.T[3] <= ROB_number;
		    	if(map_table[input_reg_1] == 0) begin
			    out.V1[3] <= value_1;
		        end
		        if(out.map_table[input_reg_2] == 0) begin
			    out.V2[3] <= value_2;
		        end
		        out.T1[3] <= out.map_table[input_reg_1];
		        out.T2[3] <= out.map_table[input_reg_2];
		    end else begin
			    out.busy_signal[4] <= 1; 
		    	out.out_opcode[4] <= opcode;
		        out.T[4] <= ROB_number;
		    	if(out.map_table[input_reg_1] == 0) begin
			    out.V1[4] <= value_1;
		        end
		        if(out.map_table[input_reg_2] == 0) begin
			    out.V2[4] <= value_2;
		        end
		        out.T1[4] <= out.map_table[input_reg_1];
		        out.T2[4] <= out.map_table[input_reg_2];
		    end
	    end else out.busy_signal[5] <= 1;
	    

            for (int i = 0; i <= 5; i++) begin
                if (done_signal[i] == 1) begin
                    out.busy_signal[i] <= 0;
                    out.out_opcode[i] <= 0;
                    out.T[i] <= 0;
                    out.T1[i] <= 0;
                    out.T2[i] <= 0;
                    out.V1[i] <= 0;
                    out.V2[i] <= 0;
                end
            end
	end
    
   end 

endmodule 
