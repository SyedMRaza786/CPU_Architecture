/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  stage_mem.sv                                        //
//                                                                     //
//  Description :  memory access (MEM) stage of the pipeline;          //
//                 this stage accesses memory for stores and loads,    //
//                 and selects the proper next PC value for branches   //
//                 based on the branch condition computed in the       //
//                 previous stage.                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"

module load_unit (
    input logic rd_unsigned,
    // the BUS_LOAD response will magically be present in the *same* cycle it's requested (0ns latency)
    // this will not be true in project 4 (100ns latency)
    input [`XLEN-1:0]   Dmem2proc_data,
    input logic valid,
    input MEM_SIZE mem_size,
    output logic [`XLEN-1:0] result,
    output logic [1:0]       proc2Dmem_command, // The memory command
    output MEM_SIZE          proc2Dmem_size,    // Size of data to read or write
    output logic [`XLEN-1:0] proc2Dmem_addr,    // Address sent to Data memory
);

    logic [`XLEN-1:0] read_data;

   

    // Pass-throughs
   
    
    
    assign result = read_data;
    assign mem_packet.dest_reg_idx = ex_mem_reg.dest_reg_idx;
    

    // Outputs from the processor to memory
    assign proc2Dmem_command = (valid) ? BUS_LOAD : BUS_NONE;
    assign proc2Dmem_size = mem_size;
    assign proc2Dmem_addr = ex_mem_reg.alu_result; // Memory address is calculated by the ALU

    // Read data from memory and sign extend the proper bits
    always_comb begin
        read_data = Dmem2proc_data;
        if (rd_unsigned) begin
            if (mem_size == BYTE) begin
                read_data[`XLEN-1:8] = 0;
            end else if (mem_size == HALF) begin
                read_data[`XLEN-1:16] = 0;
            end
        end else begin
            // signed: sign-extend the data
            if (mem_size[1:0] == BYTE) begin
                read_data[`XLEN-1:8] = {(`XLEN-8){Dmem2proc_data[7]}};
            end else if (mem_size == HALF) begin
                read_data[`XLEN-1:16] = {(`XLEN-16){Dmem2proc_data[15]}};
            end
        end
    end

endmodule // stage_mem
