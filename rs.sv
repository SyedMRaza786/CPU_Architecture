/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  RS.sv                                               //
//                                                                     //
//  Description :                                                      //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"

`define ALU 3'b001
`define LD  3'b010
`define ST  3'b011
`define FP  3'b100
module res_station (
    input             clock,          // system clock
    input             reset,          // system reset
    input             rs_valid,       // only go to next PC when true
    input [2:0]       opcode,    // taken-branch signal
    input [31:0]      ROB_number,
    input [4:0]       input_reg_1,
    input [4:0]       input_reg_2, 
    input [4:0]       dest_reg,  
    input [4:0]       done_signal,
    input [`XLEN-1:0] value_1,
    input [`XLEN-1:0] value_2,


    output[4:0]       busy_signal,
    output[6:0]       out_opcode[4:0],
    output[31:0]      T[4:0],
    output[31:0]      T1[4:0],
    output[31:0]      T2[4:0],
    output[`XLEN-1:0] V1[4:0],
    output[`XLEN-1:0] V2[4:0]

); 
    
    //logic[`XLEN-1:0] value_1, value_2; 
    logic[31:0]      map_table[31:0];
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
            value_1 <= 0;
            value_2 <= 0;
            busy_signal <= 3'b0;
            out_opcode <= 0;
            T <= 0;
            T1 <= 0;
            T2 <= 0;
            V1 <= 0;
            V2 <= 0;
            map_table <= 0;
            
	end else begin
	    map_table[dest_reg] <= ROB_number;
	    case(opcode) begin
		ALU : begin
			
		    busy_signal[0] <= 1;
		    out_opcode[0] <= opcode;
		    T[0] <= ROB_number;
		    if(map_table[input_reg_1] == 0) begin
			V1[0] <= value_1;
		    end
		    if(map_table[input_reg_2] == 0) begin
			V2[0] <= value_2;
		    end
		    T1[0] <= map_table[input_reg_1];
		    T2[0] <= map_table[input_reg_2];
		end
		LD : begin

		    busy_signal[1] <= 1;
		    out_opcode[1] <= opcode;
		    T[1] <= ROB_number;
		    if(map_table[input_reg_1] == 0) begin
			V1[1] <= value_1;
		    end
		    if(map_table[input_reg_2] == 0) begin
			V2[1] <= value_2;
		    end
		    T1[1] <= map_table[input_reg_1]
		    T2[1] <= map_table[input_reg_2]
		end
		ST : begin

		    busy_signal[2] <= 1;
		    out_opcode[2] <= opcode;
		    T[2] <= ROB_number;
		    if(map_table[input_reg_1] == 0) begin
			V1[2] <= value_1;
		    end
		    if(map_table[input_reg_2] == 0) begin
			V2[2] <= value_2;
		    end
		    T1[2] <= map_table[input_reg_1]
		    T2[2] <= map_table[input_reg_2]
		end
		FP  : begin
		    if(busy_signal[3] == 0) begin
			busy_signal[3] <= 1;
		        out_opcode[3] <= opcode;
		        T[3] <= ROB_number;
		    	if(map_table[input_reg_1] == 0) begin
			    V1[3] <= value_1;
		        end
		        if(map_table[input_reg_2] == 0) begin
			    V2[3] <= value_2;
		        end
		        T1[3] <= map_table[input_reg_1]
		        T2[3] <= map_table[input_reg_2]
		    end else begin
			busy_signal[4] <= 1; 
		    	out_opcode[4] <= opcode;
		        T[4] <= ROB_number;
		    	if(map_table[input_reg_1] == 0) begin
			    V1[4] <= value_1;
		        end
		        if(map_table[input_reg_2] == 0) begin
			    V2[4] <= value_2;
		        end
		        T1[4] <= map_table[input_reg_1]
		        T2[4] <= map_table[input_reg_2]
		    end
		end
		default : busy_signal[5] <= 1;
	    endcase

            for (int i = 0; i <= 5; i++) begin
                if (done_signal[i] == 1) begin
                    busy_signal[i] = 0;
                    opcode[i] = 0;
                    T[i] = 0;
                    T1[i] = 0;
                    T2[i] = 0;
                    V1[i] = 0;
                    V2[i] = 0;
                end
            end
	end
    end
    

endmodule // RS
