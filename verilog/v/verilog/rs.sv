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
// typedef enum logic [2:0] {
//     ALU_FU = 3'b001,
//     MULT1_FU  = 3'b010,
//     // M2 = 3'b010,
//     LS_FU  = 3'b011,
//     BR_FU  = 3'b100,
//     UNKNOWN_FU = 3'b000
// } Opcode;




module rs (
    input logic            	clock,          // system clock
    input logic            	reset,          // system reset
    input logic            	rs_valid,
    input logic            	cdb_valid,
    input logic [`XLEN-1:0] cdb_value,
    input logic [3:0]      	cdb_tag,
    input logic [`FU_OPCODE_BIT_WIDTH-1:0]     	               cdb_unit,
    input Opcode            opcode,
    // input logic [2:0]      	opcode,
    input logic [3:0]      	ROB_number,
    input logic [4:0]      	input_reg_1,
    input logic [4:0]       	input_reg_2,
    input logic [4:0]       	dest_reg,  
    input logic [4:0]       	done_signal,
    input logic [31:0]     	value_1,
    input logic [31:0]      	value_2,
    input RS 		   	    rs_table,
    input logic            	ready_in_rob_valid,
    input logic [1:0]      	ready_in_rob_register,
    input logic [`ROB_BIT_WIDTH-1:0]      	ready_rob_num, squash_index, rob_tail,
    input ID_EX_PACKET	   	id_packet,
    input logic[`RS_SIZE-1:0] 		exec_busy, 
    input logic			    squash,   

    input logic            	retire,
    input logic [4:0]      	retire_register,
    input logic [2:0]      	retire_rob_number,
    input INST             	inst,
    output RS		   	    out,
    output logic[`RS_SIZE-1:0]		exec_run    
);

    always_ff @(posedge clock) begin
      if (reset) begin
			exec_run = 5'b0;
            for (int i = 0; i < `RS_SIZE; i++) begin 
              out.busy_signal[i] <= 3'b0;
              out.out_opcode[i] <= 0;
              out.T[i] <= 0;
              out.T1[i] <= 0;
              out.T2[i] <= 0;
              out.V1[i] <= 0;
              out.V2[i] <= 0;
              out.inst[i] <= 0;
            end // for loop
            for (int i = 0; i < 32; i++)  out.map_table[i] <= 0;
        end else begin
	if (rs_valid) begin
            out = rs_table;
            if(ROB_number < 7) out.map_table[dest_reg] <= ROB_number+1;
            else out.map_table[dest_reg] <= 1;
            case (opcode) // dispatch on opcode
                ALU_FU: process_instr(1, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
                MULT1_FU:  process_instr(4, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
                LS_FU:   process_instr(2, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
                BR_FU:  process_instr(3, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
                default: process_other_instr(0, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
            endcase
        end 
            for (int i = 0; i <= `RS_SIZE; i++) begin
                if ((rs_table.map_table[rs_table.id_packet[i].inst.r.rs1] == 0 || rs_table.map_table[rs_table.id_packet[i].inst.r.rs1][0] == 1) && (rs_table.map_table[rs_table.id_packet[i].inst.r.rs2] == 0 || rs_table.map_table[rs_table.id_packet[i].inst.r.rs2][0] == 1) && exec_busy[i] == 0) begin
                    out.busy_signal[i] <= 0;
                    out.out_opcode[i] <= 0;
                    out.T[i] <= 0;
                    out.T1[i] <= 0;
                    out.T2[i] <= 0;
                    out.V1[i] <= 0;
                    out.V2[i] <= 0;
                end // done
            end // for loop

            if (ready_in_rob_valid) begin
                if(rs_table.map_table[ready_in_rob_register] == {ready_rob_num, 1'b0}) begin out.map_table[ready_in_rob_register][0] <= 1; end
            end // ready_in_rob_valid
            if (cdb_valid) begin
                if(rs_table.T1[cdb_unit] == cdb_tag) begin
                    out.V1[cdb_unit] <= cdb_value;
                end	else if(rs_table.T2[cdb_unit] == cdb_tag) begin
                    out.V2[cdb_unit] <= cdb_value;
                end
            end // cdb_valid
            if (retire) begin
                if(rs_table.map_table[retire_register][3:1] == retire_rob_number + 1) begin
                    out.map_table[retire_register] <= 4'b0;
                end
            end // retire
            if (squash) begin
                if (rob_tail > squash_index) begin // handle squash index within head and tail
                    squash_entries(0, squash_index, rob_tail, 0);
                end else begin // handle squash index wraparound
                    squash_entries(0, squash_index, rob_tail, 1);
                end
            end // squash
	    end // else: ~reset
      $display("Reservation Stations");
      $display("    +----+-----+------+--------+----+-----+----------------------------------+-----+----------------------------------+");
      $display("    | #  | Use | Exec |  FU    | rd | rs1 |                V1                | rs2 |                V2                |");
      $display("    +----+-----+------+--------+----+-----+----------------------------------+-----+----------------------------------+");
      for (int i = 0; i < `RS_SIZE; i++) begin
         if (i + 1 == rob_tail) begin
            if (i == 0) begin
               $display("T-> | %02d |     |  %d   |  ????  | %02d | %02d  | %032b | %02d | %032b |",
                        i, out.busy_signal[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 1) begin
               $display("T-> | %02d |     |  %d   |  ALU   | %02d | %02d  | %032b | %02d | %032b |",
                        i, out.busy_signal[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 2) begin
               $display("T-> | %02d |     |  %d   | LD/ST  | %02d | %02d  | %032b | %02d | %032b |",
                        i, out.busy_signal[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 3) begin
               $display("T-> | %02d |     |  %d   | BRANCH | %02d | %02d | %032b | %02d | %032b |",
                        i, out.busy_signal[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 4 || i == 5) begin
               $display("T-> | %02d |     |  %d    |  MULT  | %02d | %02d | %032b | %02d | %032b |",
                        i, out.busy_signal[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end
         end else begin
            if (i == 0) begin
               $display("    | %02d |     |  %d   |  ????  | %02d | %02d  | %032b | %02d  | %032b |",
                        i, out.busy_signal[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 1) begin
               $display("    | %02d |     |  %d   |  ALU   | %02d | %02d  | %032b | %02d  | %032b |",
                        i, out.busy_signal[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 2) begin
               $display("    | %02d |     |  %d   | LD/ST  | %02d | %02d  | %032b | %02d  | %032b |",
                        i, out.busy_signal[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 3) begin
               $display("    | %02d |     |  %d   | BRANCH | %02d | %02d  | %032b | %02d  | %032b |",
                        i, out.busy_signal[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end else if (i == 4 || i == 5) begin
               $display("    | %02d |     |  %d   |  MULT  | %02d | %02d  | %032b | %02d  | %032b |",
                        i, out.busy_signal[i], out.T[i], out.T1[i], out.V1[i], out.T2[i], out.V2[i]);
            end
         end
      end
      $display("    +----+-----+------+--------+----+-----+----------------------------------+-----+----------------------------------+");
         // $display("Entry %d:", i);
         // $display("  Busy: %b, Op: %b, T: %d, T1: %d, T2: %d, V1: %d, V2: %d", out.busy_signal[i], out.out_opcode[i], out.T[i], out.T1[i], out.T2[i], out.V1[i], out.V2[i]);
         // $display("  Instruction: %p", out.inst[i]);
      $display("\n    Map Table (only non-zero registers are displayed):");
      for (int i = 0; i < 32; i++) begin
         if (out.map_table[i] != 0) begin
            $display("     Register %d: %d", i, out.map_table[i]);
         end
      end
      $display("------------------------");
	end // always_ff

// processes `idx=0,...,4`
task process_instr(
    int idx,
    INST inst,
    logic [31:0] value_1,
    logic [31:0] value_2,
    ID_EX_PACKET id_packet,
    logic [4:0] exec_busy,
    Opcode opcode,
    logic [4:0] input_reg_1,
    logic [4:0] input_reg_2,
    logic [3:0] ROB_number
);
    begin

		if (idx <= 4 && rs_table.busy_signal[idx] == 0) begin
		    out.inst[idx] <= inst;
		    out.busy_signal[idx] <= 1;
		    out.out_opcode[idx] <= opcode;
		    if(ROB_number <= 7) out.T[idx] <= ROB_number + 1;
		    else out.T[idx] <= 1;
		    out.V1[idx] <= rs_table.map_table[input_reg_1] == 0 ? value_1 : 32'bx;
		    out.V2[idx] <= rs_table.map_table[input_reg_2] == 0 ? value_2 : 32'bx;
		    out.T1[idx] <= rs_table.map_table[input_reg_1];
		    out.T2[idx] <= rs_table.map_table[input_reg_2];
		    out.id_packet[idx] <= id_packet;
		    //exec_run[idx] <= 1;
		    exec_run[idx] <= ((rs_table.map_table[input_reg_1] == 0 || rs_table.map_table[input_reg_1][0] == 1) && (rs_table.map_table[input_reg_2] == 0 || rs_table.map_table[input_reg_2][0] == 1) && exec_busy[idx] == 0);
		end else if(idx == 4 && rs_table.busy_signal[5] == 0) begin
		    out.inst[5] <= inst;
		    out.busy_signal[5] <= 1;
		    out.out_opcode[5] <= opcode;
		    //out.T[5] <= ROB_number;
		    if(ROB_number <= 7) out.T[5] <= ROB_number + 1;
		    else out.T[5] <= 1;
		    out.V1[5] <= rs_table.map_table[input_reg_1] == 0 ? value_1 : 32'bx;
		    out.V2[5] <= rs_table.map_table[input_reg_2] == 0 ? value_2 : 32'bx;
		    out.T1[5] <= rs_table.map_table[input_reg_1];
		    out.T2[5] <= rs_table.map_table[input_reg_2];
		    out.id_packet[5] <= id_packet;
		    exec_run[idx] <= 1;
		    exec_run[5] <= (rs_table.map_table[input_reg_1] == 0 || rs_table.map_table[input_reg_1][0] == 1) && (rs_table.map_table[input_reg_2] == 0 || rs_table.map_table[input_reg_2][0] == 1) && exec_busy[5] == 0;

		end
	
    end
endtask

task process_other_instr(
    int idx,
    INST inst,
    logic [31:0] value_1,
    logic [31:0] value_2,
    ID_EX_PACKET id_packet,
    logic [4:0] exec_busy,
    Opcode opcode,
    logic [4:0] input_reg_1,
    logic [4:0] input_reg_2,
    logic [3:0] ROB_number
);
    begin
        out.inst[idx] <= inst;
        out.busy_signal[idx] <= 1;
        out.out_opcode[idx] <= opcode;
        if(ROB_number <= 7) out.T[idx] <= ROB_number + 1;
        else out.T[idx] <= 1;
        out.V1[idx] <= rs_table.map_table[input_reg_1] == 0 ? value_1 : 32'b0;
        out.V2[idx] <= rs_table.map_table[input_reg_2] == 0 ? value_2 : 32'b0;
        out.T1[idx] <= rs_table.map_table[input_reg_1];
        out.T2[idx] <= rs_table.map_table[input_reg_2];
        out.id_packet[idx] <= id_packet;
	exec_run[idx] <= 1;
        exec_run[idx] <= (rs_table.map_table[input_reg_1] == 0 || rs_table.map_table[input_reg_1][0] == 1) && (rs_table.map_table[input_reg_2] == 0 || rs_table.map_table[input_reg_2][0] == 1) && exec_busy[idx] == 0;
    end
endtask

task squash_entries(
    int start,
    int squash_index,
    int rob_tail,
    bit wrap_around
);
    for (int i = start; i < `RS_SIZE; i++) begin
        if ((wrap_around && ((rs_table.T[i] >= squash_index && rs_table.T[i] < 7) || (rs_table.T[i] <= rob_tail))) ||
            (!wrap_around && (rs_table.T[i] <= squash_index && rs_table.T[i] > rob_tail))) begin
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
endtask

endmodule // rs.sv

