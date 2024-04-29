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
`include "sys_defs.svh"
`define XLEN  32
`define RS_SIZE 5
// `define ALU 3'b001
// `define LD  3'b010
// `define ST  3'b011
// `define FP  3'b100
typedef enum logic [2:0] {
    ALU = 3'b001,
    LD  = 3'b010,
    ST  = 3'b011,
    FP  = 3'b100
} Opcode;




module rs (
    input logic            	clock,          // system clock
    input logic            	reset,          // system reset
    input logic            	rs_valid,
    input logic            	cdb_valid,
    input logic [`XLEN-1:0] cdb_value,
    input logic [3:0]      	cdb_tag,
    input logic [2:0]     	cdb_unit,
    input Opcode            opcode,
    // input logic [2:0]      	opcode,
    input logic [3:0]      	ROB_number,
    input logic [4:0]      	input_reg_1,
    input logic[4:0]       	input_reg_2, 
    input logic[4:0]       	dest_reg,  
    input logic[4:0]       	done_signal,
    input logic [31:0]     	value_1,
    input logic[31:0]      	value_2,
    input RS 		   	    rs_table,
    input logic            	ready_in_rob_valid,
    input logic [1:0]      	ready_in_rob_register,
    input logic [2:0]      	ready_rob_num, squash_index, rob_tail,
    input ID_EX_PACKET	   	id_packet,
    input logic[4:0] 		exec_busy, 
    input logic			    squash,   

    input logic            	retire,
    input logic [4:0]      	retire_register,
    input logic [2:0]      	retire_rob_number,
    input INST             	inst,
    output RS		   	    out,
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
//    logic [2:0] try_code = `LD;
  Opcode try_code = LD;

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
	    $display("rs.sv: exec_run=%b", exec_run);
        if (reset) begin
			exec_run = 5'b0;
            for (int i = 0; i < `RS_SIZE; i++) begin
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
            end // for loop
            for (int i = 0; i < 32; i++)  out.map_table[i] <= 0;
        end else if (rs_valid) begin
            out = rs_table;
            out.map_table[dest_reg] <= ROB_number;
            case (opcode) // dispatch on opcode
                ALU: process_instr(0, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
                LD:  process_instr(1, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
                ST:  process_instr(2, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
                FP:  process_instr(3, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
                default: process_other_instr(4, inst, value_1, value_2, id_packet, exec_busy, opcode, input_reg_1, input_reg_2, ROB_number);
            endcase
        end else begin
            for (int i = 0; i <= `RS_SIZE; i++) begin
                if (done_signal[i] == 1) begin
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
                if(rs_table.map_table[retire_register][3:1] == retire_rob_number) begin
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
        $display("RS Contents:");
        for (int i = 0; i < 5; i++) begin
            $display("Entry %d:", i);
            $display("  Busy: %b", out.busy_signal[i]);
            $display("  Opcode: %b", out.out_opcode[i]);
            $display("  Dest Tag: %d", out.T[i]);
            $display("  Tag1: %d", out.T1[i]);
            $display("  Tag2: %d", out.T2[i]);
            $display("  Value1: %d", out.V1[i]);
            $display("  Value2: %d", out.V2[i]);
            $display("  Instruction: %p", out.inst[i]);
        end
        $display("Map Table:");
        for (int i = 0; i < 32; i++) begin
            $display("  Register %d: %d", i, out.map_table[i]);
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
        if (rs_table.busy_signal[idx] == 0) begin
            out.inst[idx] <= inst;
            out.busy_signal[idx] <= 1;
            out.out_opcode[idx] <= opcode;
            out.T[idx] <= ROB_number;
            out.V1[idx] <= rs_table.map_table[input_reg_1] == 0 ? value_1 : 32'bx;
            out.V2[idx] <= rs_table.map_table[input_reg_2] == 0 ? value_2 : 32'bx;
            out.T1[idx] <= rs_table.map_table[input_reg_1];
            out.T2[idx] <= rs_table.map_table[input_reg_2];
            out.id_packet[idx] <= id_packet;
            exec_run[idx] <= rs_table.map_table[input_reg_1] == 0 && rs_table.map_table[input_reg_2] == 0 && exec_busy[idx] == 0;
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
        out.T[idx] <= ROB_number;
        out.V1[idx] <= rs_table.map_table[input_reg_1] == 0 ? value_1 : 32'bx;
        out.V2[idx] <= rs_table.map_table[input_reg_2] == 0 ? value_2 : 32'bx;
        out.T1[idx] <= rs_table.map_table[input_reg_1];
        out.T2[idx] <= rs_table.map_table[input_reg_2];
        out.id_packet[idx] <= id_packet;
        exec_run[idx] <= rs_table.map_table[input_reg_1] == 0 && rs_table.map_table[input_reg_2] == 0 && exec_busy[idx] == 0;
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

