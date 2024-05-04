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

`define DEBUG

module rob (
    input logic                         clock,          // system clock
    input logic                         reset,          // system reset
    input logic                         valid,
    input logic                         value_valid,
    input logic [`ROB_BIT_WIDTH-1:0]    value_tag,
    input logic [`FU_OPC_BIT_LEN-1:0]   opcode,
    input logic [`REG_BITS-1:0]         input_reg_1,
    input logic [`REG_BITS-1:0]         input_reg_2,
    input logic [`REG_BITS-1:0]         dest_reg,
    input logic [`XLEN-1:0]             value,
    input ROB                           rob_in,
    input logic                         squash,
    input logic                         retire_in,
    input ID_EX_PACKET                  id_packet,
    input logic [`ROB_BIT_LEN-1:0]      squash_index,
    output ROB                          rob_out,
    output logic                        rob_is_full,
    output logic                        retire_out,
    output logic                        writeback_valid
);

    logic [`ROB_BIT_LEN-1:0] temp_tail;
    always_ff @(posedge clock) begin
        if (reset) begin
            rob_out.head <= `ROB_FIRST_IDX, rob_out.tail <= `ROB_FIRST_IDX;
            for(int i = 0; i < `ROB_SIZE; i++) begin
                rob_out.opcodes[i] <= '0; // 0-fill
                rob_out.input_reg_1s[i] <= '0;
                rob_out.input_reg_2s[i] <= '0;
                rob_out.Rs[i] <= '0;
                rob_out.Vs[i] <= '0;
                rob_out.is_full <= 1'b0;
                rob_out.buffer_completed <= 1'b0;
                rob_out.id_packet[i] <= '0;
                temp_tail <= 1'b0;
                rob_out.completed[i] <= 1'b0;
            end

	    end else begin
	        if (rob_in.completed[rob_in.head]) begin
		        retire_out <= 1'b1;
		    if (rob_in.Rs[rob_in.head] != 0) begin
                writeback_valid <= 1'b0;
		    end else writeback_valid <= 1'b0;
        end else retire_out <= 1'b0;
            rob_out <= rob_in;

            if (valid == 1) begin
                if (rob_in.head == `ROB_FIRST_IDX && rob_in.tail == `ROB_FIRST_IDX) begin
                    rob_out.head            <= `ROB_FIRST_IDX;
                    rob_out.tail            <= `ROB_FIRST_IDX;
                    rob_out.opcodes[0]      <= opcode;
                    rob_out.input_reg_1s[0] <= input_reg_1;
                    rob_out.input_reg_2s[0] <= input_reg_2;
                    rob_out.Rs[0]           <= dest_reg;
                    rob_out.id_packet[0]  <= id_packet;
                end else begin
                    if(rob_in.tail == 7) begin
                        rob_out.opcodes[0] <= opcode;
                        rob_out.input_reg_1s[0] <= input_reg_1;
                        rob_out.input_reg_2s[0] <= input_reg_2;
                        rob_out.Rs[0] <= dest_reg;
                        rob_out.completed[0] <= 1'b0;
                        rob_out.id_packet[0]    <= id_packet;
                        rob_out.tail <= `ROB_BIT_LEN'b0;
                    end else begin
				        rob_out.completed[rob_in.tail] <= 1'b0;
			            rob_out.opcodes[rob_in.tail] <= opcode;
                        rob_out.input_reg_1s[rob_in.tail] <= input_reg_1;
                        rob_out.input_reg_2s[rob_in.tail] <= input_reg_2;
                        rob_out.Rs[rob_in.tail] <= dest_reg;
                        rob_out.id_packet[rob_in.tail]    <= id_packet;
                        if (rob_in.tail == (`ROB_LAST_IDX - 1)) begin: TAIL_IS_6
				            if (rob_in.head == `ROB_FIRST_IDX) begin
                                rob_out.is_full <= 1'b1;
                                rob_out.tail <= `ROB_LAST_IDX;
		                    end else begin
				               rob_out.tail <= `ROB_LAST_IDX;
                            end
                        end else begin
                            if(rob_in.head != (rob_in.tail + 2)) begin
                                rob_out.tail <= rob_in.tail + 1;
                            end else begin
                                rob_out.tail <= rob_in.tail + 1;
                                rob_out.is_full <= 1;
                            end
                        end
                    end
                end
            end

                if (value_valid == 1) begin
                    $display("   ```value_tag: %d     value: %d", value_tag, value);
                    rob_out.Vs [value_tag] <= value;
                    rob_out.completed[value_tag] <= 1;
                end
                if(retire_in == 1) begin
	                $display("Retire INNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN");
                    rob_out.opcodes[rob_in.head] <= '0;
                    rob_out.input_reg_1s[rob_in.head] <= '0;
                    rob_out.input_reg_2s[rob_in.head] <= `REG_ADDR_WIDTH'b0;
                    rob_out.Rs[rob_in.head] <= `REG_ADDR_WIDTH'b0;
                    rob_out.Vs[rob_in.head] <= `XLEN'b0;
                    rob_out.is_full <= 0;
                    rob_out.id_packet[rob_in.head]    <= 0;
                if (rob_in.head == `ROB_LAST_IDX) begin
                    rob_out.head <= `ROB_FIRST_IDX; // 1
                end else begin
                    rob_out.head <= rob_in.head + 1;
                end
            end
            if (squash) begin
                if (rob_in.tail > squash_index) begin
                    for (int i = (squash_index + 1); i < rob_in.tail; i++) begin
                        rob_out.tail <= squash_index;
                        rob_out.opcodes[i] <= '0;
                        rob_out.input_reg_1s[i] <= '0;
                        rob_out.input_reg_2s[i] <= '0;
                        rob_out.Rs[i] <= '0;
                        rob_out.Vs[i] <= '0;
                        rob_out.is_full <= 0;
                        rob_out.buffer_completed <= 0;
                        rob_out.id_packet[i] <= '0;
                    end
		        end else begin
                    for (int i = (squash_index + 1); i < `ROB_SIZE; i++) begin
                        rob_out.tail <= squash_index;
                        rob_out.opcodes[i] <= '0;
                        rob_out.input_reg_1s[i] <= '0;
                        rob_out.input_reg_2s[i] <= '0;
                        rob_out.Rs[i] <= '0;
                        rob_out.Vs[i] <= '0;
                        rob_out.is_full <= 0;
                        rob_out.buffer_completed <= 0;
                        rob_out.id_packet[i] <= '0;
                    end
                    for (int j = 0; j < rob_in.tail; j++) begin
                        rob_out.tail <= squash_index;
                        rob_out.opcodes[i] <= '0;
                        rob_out.input_reg_1s[i] <= '0;
                        rob_out.input_reg_2s[i] <= '0;
                        rob_out.Rs[i] <= '0;
                        rob_out.Vs[i] <= '0;
                        rob_out.is_full <= 0;
                        rob_out.buffer_completed <= 0;
                        rob_out.id_packet[i] <= '0;

                    end
                end
            end
        end
`ifdef DEBUG
        $display("ROB Contents:");
        $display("Head: %d, Tail: %d, Buffer is_full: %d, Buffer Completed: %d", rob_out.head, rob_out.tail, rob_out.is_full, rob_out.buffer_completed);
        $display("OP                | I1                   | I2                  | D                    | V");
        for (int i = 0; i < `ROB_SIZE; i++) begin
            $display("%b                | %d                   | %d                  | %d                    | %d", rob_out.opcodes[i], rob_out.input_reg_1s[i], rob_out.input_reg_2s[i], rob_out.Rs[i], rob_out.Vs[i]);
        end
        $display("------------------------");
`endif // DEBUG
    end

task clear_rob_entries(
    input integer start_idx,
    input integer end_idx,
    inout ROB rob_in,
    inout ROB rob_out
);
    integer i;
    for (i = start_idx; i < rob_in.tail; i++) begin
        rob_out.opcodes[i] = `FU_OPCODE_WIDTH'b0;
        rob_out.input_reg_1s[i] = `REG_ADDR_WIDTH'b0;
        rob_out.input_reg_2s[i] = `REG_ADDR_WIDTH'b0;
        rob_out.Rs[i] = `REG_ADDR_WIDTH'b0;
        rob_out.Vs[i] = `XLEN'b0;
        rob_out.is_full = 1'b0;
        rob_out.buffer_completed = 1'b0;
        rob_out.id_packet[i] = '0;
    end
    rob_out.tail = start_idx;  // Set the tail after clearing
endtask


endmodule
