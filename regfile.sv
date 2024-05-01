/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name:  regfile.sv                                           //
//                                                                     //
//  Description:  This module implements a register file for use in    //
//                the ID & WB stages of a 2-way superscalar pipeline.  //
//                Notably, this design includes internal forwarding    //
//                to mitigate RAW hazards without external forwarding  //
//                logic.                                               //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`include "verilog/sys_defs.svh"

module regfile (
  input clock, // system clock
  // note: no system reset, register values must be written before they can be read
  input [4:0] readA_idx_1, readB_idx_1, readA_idx_2, readB_idx_2,
  input [4:0] write_idx_1, write_idx_2,
  input write_en_1, write_en_2,
  input [`XLEN-1:0] write_data_1, write_data_2,

  output logic [`XLEN-1:0] readA_out_1, readB_out_1, readA_out_2, readB_out_2
);

  logic [31:1] [`XLEN-1:0] registers; // 31 XLEN-length Registers (0 is known)

  localparam NUM_REGS = 32;

  // Read ports
  assign readA_out_1 = (readA_idx_1 == 0) ? 0 :
                       (write_en_1 && (write_idx_1 == readA_idx_1)) ? write_data_1 :
                       (write_en_2 && (write_idx_2 == readA_idx_1)) ? write_data_2 :
                       registers[readA_idx_1];

  assign readB_out_1 = (readB_idx_1 == 0) ? 0 :
                       (write_en_1 && (write_idx_1 == readB_idx_1)) ? write_data_1 :
                       (write_en_2 && (write_idx_2 == readB_idx_1)) ? write_data_2 :
                       registers[readB_idx_1];

  assign readA_out_2 = (readA_idx_2 == 0) ? 0 :
                       (write_en_1 && (write_idx_1 == readA_idx_2)) ? write_data_1 :
                       (write_en_2 && (write_idx_2 == readA_idx_2)) ? write_data_2 :
                       registers[readA_idx_2];

  assign readB_out_2 = (readB_idx_2 == 0) ? 0 :
                       (write_en_1 && (write_idx_1 == readB_idx_2)) ? write_data_1 :
                       (write_en_2 && (write_idx_2 == readB_idx_2)) ? write_data_2 :
                       registers[readB_idx_2];

  // Write port
  always_ff @(posedge clock) begin
    if (write_en_1 && write_en_2 && write_idx_1 == write_idx_2) begin
      if (write_idx_1 < NUM_REGS) begin
        assert(!$isunknown(write_idx_1) && !$isunknown(write_idx_2))
          else $error("Attempting to write to the same write indices %d %d", write_idx_1, write_idx_2);
        registers[write_idx_2] <= write_data_2;
      end else begin
        $error("Invalid write index: %d", write_idx_1);
      end
    end else begin
      if (write_en_1 && write_idx_1 < NUM_REGS) begin
        registers[write_idx_1] <= write_data_1;
      end
      if (write_en_2 && write_idx_2 < NUM_REGS) begin
        registers[write_idx_2] <= write_data_2;
      end
    end
  end

  `ifdef DEBUG
  always @(posedge clock) begin
      $display("========== Clock Cycle %d ==========", $time);
      $display("Read Operations:");
      $display("  readA_idx_1: %d, readA_out_1: %h", readA_idx_1, readA_out_1);
      $display("  readB_idx_1: %d, readB_out_1: %h", readB_idx_1, readB_out_1);
      $display("  readA_idx_2: %d, readA_out_2: %h", readA_idx_2, readA_out_2);
      $display("  readB_idx_2: %d, readB_out_2: %h", readB_idx_2, readB_out_2);
      $display("Write Operations:");
      if (write_en_1) $display("  write_idx_1: %d, write_data_1: %h", write_idx_1, write_data_1);
      if (write_en_2) $display("  write_idx_2: %d, write_data_2: %h", write_idx_2, write_data_2);
      $display("Register Contents:");
      for (int i = 1; i < NUM_REGS; i++) begin
          $display("  Register %2d: %h", i, registers[i]);
      end
      $display("====================================");
  end
`endif

endmodule // regfile