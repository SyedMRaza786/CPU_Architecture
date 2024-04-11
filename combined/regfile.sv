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
    input             clock, // system clock
    // note: no system reset, register values must be written before they can be read
    input [4:0]       read_idx_1, read_idx_2, read_idx_3, read_idx_4,
    input [4:0]       write_idx,
    input             write_en,
    input [`XLEN-1:0] write_data,

    output logic [`XLEN-1:0] read_out_1, read_out_2, read_out_3, read_out_4
);

    logic [31:1] [`XLEN-1:0] registers; // 31 XLEN-length Registers (0 is known)

    // Read port 1
    always_comb begin
        if (read_idx_1 == `ZERO_REG) begin
            read_out_1 = 0;
        end else if (write_en && (write_idx == read_idx_1)) begin
            read_out_1 = write_data; // internal forwarding
        end else begin
            read_out_1 = registers[read_idx_1];
        end
    end

    // Read port 2
    always_comb begin
        if (read_idx_2 == `ZERO_REG) begin
            read_out_2 = 0;
        end else if (write_en && (write_idx == read_idx_2)) begin
            read_out_2 = write_data; // internal forwarding
        end else begin
            read_out_2 = registers[read_idx_2];
        end
    end

    // Read port 3
    always_comb begin
        if (read_idx_3 == `ZERO_REG) begin
            read_out_3 = 0;
        end else if (write_en && (write_idx == read_idx_3)) begin
            read_out_3 = write_data;
        end else begin
            read_out_3 = registers[read_idx_3];
        end
    end

    // Read port 4
    always_comb begin
        if (read_idx_4 == `ZERO_REG) begin
            read_out_4 = 0;
        end else if (write_en && (write_idx == read_idx_4)) begin
            read_out_4 = write_data;
        end else begin
            read_out_4 = registers[read_idx_4];
        end
    end

    // Write port
    always_ff @(posedge clock) begin
        if (write_en && write_idx != `ZERO_REG) begin
            registers[write_idx] <= write_data;
        end
    end

endmodule // regfile
