/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline.sv                                         //
//                                                                     //
//  Description :  Top-level module of the verisimple pipeline;        //
//                 This instantiates and connects the 5 stages of the  //
//                 Verisimple pipeline together.                       //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"

module pipeline (
    input        clock,             // System clock
    input        reset,             // System reset
    input [3:0]  mem2proc_response, // Tag from memory about current request
    input [63:0] mem2proc_data,     // Data coming back from memory
    input [3:0]  mem2proc_tag,      // Tag from memory about current reply

    output logic [1:0]       proc2mem_command, // Command sent to memory
    output logic [`XLEN-1:0] proc2mem_addr,    // Address sent to memory
    output logic [63:0]      proc2mem_data,    // Data sent to memory
    output MEM_SIZE          proc2mem_size,    // Data size sent to memory

    // Note: these are assigned at the very bottom of the module
    output logic [3:0]       pipeline_completed_insts,
    output EXCEPTION_CODE    pipeline_error_status,
    output logic [4:0]       pipeline_commit_wr_idx,
    output logic [`XLEN-1:0] pipeline_commit_wr_data,
    output logic             pipeline_commit_wr_en,
    output logic [`XLEN-1:0] pipeline_commit_NPC,

    // Debug outputs: these signals are solely used for debugging in testbenches
    // Do not change for project 3
    // You should definitely change these for project 4
    output logic [`XLEN-1:0] if_NPC_dbg,
    output logic [31:0]      if_inst_dbg,
    output logic             if_valid_dbg,
    output logic [`XLEN-1:0] if_id_NPC_dbg,
    output logic [31:0]      if_id_inst_dbg,
    output logic             if_id_valid_dbg,
    output logic [`XLEN-1:0] id_ex_NPC_dbg,
    output logic [31:0]      id_ex_inst_dbg,
    output logic             id_ex_valid_dbg,
    output logic [`XLEN-1:0] ex_mem_NPC_dbg,
    output logic [31:0]      ex_mem_inst_dbg,
    output logic             ex_mem_valid_dbg,
    output logic [`XLEN-1:0] mem_wb_NPC_dbg,
    output logic [31:0]      mem_wb_inst_dbg,
    output logic             mem_wb_valid_dbg
);

    //////////////////////////////////////////////////
    //                                              //
    //                Pipeline Wires                //
    //                                              //
    //////////////////////////////////////////////////

    // Pipeline register enables
    logic if_id_enable, id_ex_enable, ex_mem_enable, mem_wb_enable;
    logic [2:0] cdb_reg;
    logic [`XLEN-1:0] cdb_val;

    // Outputs from IF-Stage and IF/ID Pipeline Register
    logic [`XLEN-1:0] proc2Imem_addr;
    IF_ID_PACKET if_packet, if_id_reg;

    // Outputs from ID stage and ID/EX Pipeline Register
    ID_EX_PACKET id_packet, id_ex_reg;

    // Outputs from EX-Stage and EX/MEM Pipeline Register
    EX_MEM_PACKET ex_packet, ex_mem_reg;

    // Outputs from MEM-Stage and MEM/WB Pipeline Register
    MEM_WB_PACKET mem_packet, mem_wb_reg, temp_mem_wb_reg;

    // Outputs from MEM-Stage to memory
    logic [`XLEN-1:0] proc2Dmem_addr;
    logic [`XLEN-1:0] proc2Dmem_data;
    logic [1:0]       proc2Dmem_command;
    MEM_SIZE          proc2Dmem_size;

    // Outputs from WB-Stage (These loop back to the register file in ID)
    logic             wb_regfile_en;
    logic [4:0]       wb_regfile_idx;
    logic [`XLEN-1:0] wb_regfile_data;
    logic [2:0]       current_opcode;


    //////////////////////////////////////////////////
    //                                              //
    //                Memory Outputs                //
    //                                              //
    //////////////////////////////////////////////////

    // these signals go to and from the processor and memory
    // we give precedence to the mem stage over instruction fetch
    // note that there is no latency in project 3
    // but there will be a 100ns latency in project 4

    always_comb begin
        if (proc2Dmem_command != BUS_NONE) begin // read or write DATA from memory
            proc2mem_command = proc2Dmem_command;
            proc2mem_addr    = proc2Dmem_addr;
            proc2mem_size    = proc2Dmem_size;  // size is never DOUBLE in project 3
        end else begin                          // read an INSTRUCTION from memory
            proc2mem_command = BUS_LOAD;
            proc2mem_addr    = proc2Imem_addr;
            proc2mem_size    = DOUBLE;          // instructions load a full memory line (64 bits)
        end
        proc2mem_data = {32'b0, proc2Dmem_data};
    end

    //////////////////////////////////////////////////
    //                                              //
    //                  Valid Bit                   //
    //                                              //
    //////////////////////////////////////////////////

    // This state controls the stall signal that artificially forces IF
    // to stall until the previous instruction has completed.
    // For project 3, start by setting this to always be 1

    logic next_if_valid;


    decoder decoder_0(
	.inst(if_packet.inst), .valid(next_if_valid), .opcode(current_opcode)


    );
    logic value_valid, alu_valid, ml1_valid, ml2_valid, ldst_valid, br_valid, value_valid;
    logic [2:0] value_tag;
    ROB rob_table;
    RS  rs_table;
    logic [4:0] valid_cdb_out;
    //////////////////////////////////////////////////
    //                                              //
    //                  IF-Stage                    //
    //                                              //
    //////////////////////////////////////////////////

    stage_if stage_if_0 (
        // Inputs
        .clock (clock),
        .reset (reset),
        .if_valid       (next_if_valid),
        .take_branch    (ex_mem_reg.take_branch),
        .branch_target  (ex_mem_reg.alu_result),
        .Imem2proc_data (mem2proc_data),

        // Outputs
        .if_packet      (if_packet),
        .proc2Imem_addr (proc2Imem_addr)
    );

    // debug outputs
    assign if_NPC_dbg   = if_packet.NPC;
    assign if_inst_dbg  = if_packet.inst;
    assign if_valid_dbg = if_packet.valid;

    //////////////////////////////////////////////////
    //                                              //
    //            IF/ID Pipeline Register           //
    //                                              //
    //////////////////////////////////////////////////

    assign if_id_enable = 1'b1; // always enabled
    // synopsys sync_set_reset "reset"
    always_ff @(posedge clock) begin
        if (reset) begin
            if_id_reg.inst  <= `NOP;
            if_id_reg.valid <= `FALSE;
            if_id_reg.NPC   <= 0;
            if_id_reg.PC    <= 0;
            next_if_valid <= 1;
        end else if (if_id_enable) begin
	    if(rob_table.buffer_full == 0) begin
	        if(current_opcode == 3'b000 && rs_table.busy_signal[0] == 1) begin
		    if_id_reg <= if_id_reg;
         	    next_if_valid <= 0;
		end else if(current_opcode == 3'b001 && rs_table.busy_signal[1] == 1 && rs_table.busy_signal[2] == 1) begin
		    if_id_reg <= if_id_reg;
         	    next_if_valid <= 0;
		end else if(current_opcode == 3'b011 && rs_table.busy_signal[3] == 1) begin
		    if_id_reg <= if_id_reg;
    		    next_if_valid <= 0;
		end else if(current_opcode == 3'b100 && rs_table.busy_signal[4] == 1) begin
                    if_id_reg <= if_id_reg;
		    next_if_valid <= 0;
		end else begin
		    if_id_reg <= if_packet;
		    if ((ex_packet.rd_mem != 0 || ex_packet.wr_mem != 0)) begin
	                next_if_valid <= 0;
	    	    end else begin
			next_if_valid <= 1;
		    end
	    end else begin
		if_id_reg <= if_id_reg;
		next_if_valid <= 0;
                
	    end
            
        end
    end

    // debug outputs
    assign if_id_NPC_dbg   = if_id_reg.NPC;
    assign if_id_inst_dbg  = if_id_reg.inst;
    assign if_id_valid_dbg = if_id_reg.valid;

    //////////////////////////////////////////////////
    //                                              //
    //                  ID-Stage                    //
    //                                              //
    //////////////////////////////////////////////////
    stage_id stage_id_0 (
        // Inputs
        .clock (clock),
        .reset (reset),
        .if_id_reg        (if_id_reg),
        .wb_regfile_en    (wb_regfile_en),
        .wb_regfile_idx   (wb_regfile_idx),
        .wb_regfile_data  (wb_regfile_data),

        // Output
        .id_packet (id_packet)
    );
/*
    decoder decoder0 (
        // Inputs
        .inst        (if_id_reg.inst),
	.valid       (if_if_reg.valid),

	.opa_select  (opa_select),
        .opb_select  (opb_select),
        .has_dest    (has_dest), // if there is a destination register
        .alu_func    (alu_func),
        .rd_mem      (rd_mem), 
        .wr_mem      (wb_mem), 
        .cond_branch (cond_branch),
        .uncond_branch (uncond_branch),
        .csr_op      (csr_op), // used for CSR operations, we only use this as a cheap way to get the return code out
        .halt        (halt),   // non-zero on a halt
        .illegal     (illegal) // non-zero on an illegal instruction
    );
*/
    //////////////////////////////////////////////////
    //                                              //
    //                  Dispatch-Part               //
    //                                              //
    //////////////////////////////////////////////////

    assign id_ex_enable = 1'b1; // always enabled
    // synopsys sync_set_reset "reset"
    always_ff @(posedge clock) begin
        if (reset) begin
            id_ex_reg <= '{
                `NOP, // we can't simply assign 0 because NOP is non-zero
                {`XLEN{1'b0}}, // PC
                {`XLEN{1'b0}}, // NPC
                {`XLEN{1'b0}}, // rs1 select
                {`XLEN{1'b0}}, // rs2 select
                OPA_IS_RS1,
                OPB_IS_RS2,
                `ZERO_REG,
                ALU_ADD,
                1'b0, // rd_mem
                1'b0, // wr_mem
                1'b0, // cond
                1'b0, // uncond
                1'b0, // halt
                1'b0, // illegal
                1'b0, // csr_op
                1'b0  // valid
            };
        end else if (id_ex_enable) begin
	    if(rob_table.buffer_full == 0) begin
	        if(current_opcode == 3'b000 && rs_table.busy_signal[0] == 1) begin
		    id_ex_reg <= id_ex_reg;
		    rob_valid <= 0;
            	    rs_valid  <= 0;
		end else if(current_opcode == 3'b001 && rs_table.busy_signal[1] == 1 && rs_table.busy_signal[2] == 1) begin
		    id_ex_reg <= id_ex_reg;
		    rob_valid <= 0;
            	    rs_valid  <= 0;
		end else if(current_opcode == 3'b011 && rs_table.busy_signal[3] == 1) begin
		    id_ex_reg <= id_ex_reg;
		    rob_valid <= 0;
            	    rs_valid  <= 0;
		end else if(current_opcode == 3'b100 && rs_table.busy_signal[4] == 1) begin
		    id_ex_reg <= id_ex_reg;
		    rob_valid <= 0;
            	    rs_valid  <= 0;
		end else begin
		    id_ex_reg <= id_packet;
	    	    rob_valid <= 1;
            	    rs_valid  <= 1;
	    end else begin
		id_ex_reg <= id_ex_reg;
		rob_valid <= 0;
                rs_valid  <= 0;
	    end
        end
    end

    // debug outputs
    assign id_ex_NPC_dbg   = id_ex_reg.NPC;
    assign id_ex_inst_dbg  = id_ex_reg.inst;
    assign id_ex_valid_dbg = id_ex_reg.valid;



    rob rob_unit(.clock(clock), .reset(reset), .valid(rob_valid), .value_valid(value_valid), .value_tag(value_tag), 
    .opcode(current_opcode), .input_reg_1(id_packet.inst.r.rs1), .input_reg_2(id_packet.inst.r.rs2), .dest_reg(id_packet.inst.r.rd), 
    .value(value_rob), .commit(commit_rob), .rob_table(rob_table), .out(rob_table));


    
    rs rs_unit(.clock(clock), .reset(reset), .rs_valid(rs_valid), .rs_cdb_valid(rs_cdb_valid), .rs_cdb_tag(rs_cdb_tag), .done_alu(done_alu),
    .done_ml1(done_ml1), .done_ml2(done_ml2), .done_ls(done_ls), .done_br(done_br), 
    .opcode(current_opcode), .operation_type(id_packet.inst), .ROB_number(tail), .input_reg_1(id_packet.inst.r.rs1), .input_reg_2(id_packet.inst.r.rs2),
    .dest_reg(id_packet.inst.r.rd), .done_signal(rs_done_signal), .value_1(id_packet.rs1_value), .value_2(id_packet.rs_V2), 
    .rs_table(rs_table), .out(rs_table), .alu_valid(alu_valid), .ml1_valid(ml1_valid), .ml2_valid(ml2_valid), .ldst_valid(ldst_valid), .br_valid(br_valid) );



    //////////////////////////////////////////////////
    //                                              //
    //                  EX-Stage                    //
    //                                              //
    //////////////////////////////////////////////////

    alu alu_0 (
        // Input
	.valid (alu_valid),
        .id_ex_reg (id_ex_reg),
	.rs_table  (rs_table),
        // Output
        .ex_packet (ex_packet_alu),
	.done  (done_alu)
    );

    multiplier multiplier_0 (
        // Input
	.valid (ml1_valid),
        .id_ex_reg (id_ex_reg),
	.rs_table  (rs_table),
        // Output
        .ex_packet (ex_packet_mult),
	.done  (done_mult)
    );

    multiplier multiplier_1 (
        // Input
	.valid (ml2_valid),
        .id_ex_reg (id_ex_reg),
	.rs_table  (rs_table),
        // Output
        .ex_packet (ex_packet_mult1),
	.done  (done_mult1)
    );

    load_store load_store_0(
	.valid (ls_valid),
	.id_ex_reg (id_ex_reg),
	.rs_table  (rs_table),
        // Output
        .ex_packet (ex_packet_load_store),
	.done  (done_load_store)

    );

    brancher brancher_0(
	.valid branch_valid),
	.id_ex_reg (id_ex_reg),
	.rs_table  (rs_table),
        // Output
        .ex_packet (ex_packet_branch),
	.done  (done_branch)

    );

    //////////////////////////////////////////////////
    //                                              //
    //           EX/MEM Pipeline Register           //
    //                                              //
    //////////////////////////////////////////////////

    assign ex_mem_enable = 1'b1; // always enabled
    // synopsys sync_set_reset "reset"
    always_ff @(posedge clock) begin
        if (reset) begin
            ex_mem_inst_dbg <= `NOP; // debug output
            ex_mem_reg      <= 0;    // the defaults can all be zero!
	    ex_mem_reg_alu  <= 0;
            ex_mem_reg_mult <= 0;
            ex_mem_reg_load <= 0;
            ex_mem_reg_store <= 0;
            ex_mem_reg_branch <= 0;
        end else if (ex_mem_enable) begin
            ex_mem_inst_dbg <= id_ex_inst_dbg; // debug output, just forwarded from ID
            ex_mem_reg      <= ex_packet;
	    if(done_alu) begin
	        ex_mem_reg_alu  <= ex_packet_alu;
	    end
	    if(done_mult1) begin
                ex_mem_reg_mult0 <= ex_packet_mult0;
	    end
	    if(done_load_store) begin
                ex_mem_reg_load_store <= ex_packet_load_store;
	    end
	    if(done_mult1) begin
                ex_mem_reg_mult1 <= ex_packet_mult1;
	    end
	    if(done_branch) begin
                ex_mem_reg_branch <= ex_packet_branch;
	    end
        end
    end

    // debug outputs
    assign ex_mem_NPC_dbg   = ex_mem_reg.NPC;
    assign ex_mem_valid_dbg = ex_mem_reg.valid;

    //////////////////////////////////////////////////
    //                                              //
    //                 MEM-Stage                    //
    //                                              //
    //////////////////////////////////////////////////

    stage_mem stage_mem_0 (
        // Inputs
        .ex_mem_reg     (ex_mem_reg_load_store),
        .Dmem2proc_data (mem2proc_data[`XLEN-1:0]), // for p3, we throw away the top 32 bits

        // Outputs
        .mem_packet        (mem_packet_ls),
        .proc2Dmem_command (proc2Dmem_command),
        .proc2Dmem_size    (proc2Dmem_size),
        .proc2Dmem_addr    (proc2Dmem_addr),
        .proc2Dmem_data    (proc2Dmem_data)
    );

    stage_mem stage_mem_2 (
        // Inputs
        .ex_mem_reg     (ex_mem_reg_alu),
        .Dmem2proc_data (mem2proc_data[`XLEN-1:0]), // for p3, we throw away the top 32 bits

        // Outputs
        .mem_packet        (mem_packet_alu),
        .proc2Dmem_command (proc2Dmem_command),
        .proc2Dmem_size    (proc2Dmem_size),
        .proc2Dmem_addr    (proc2Dmem_addr),
        .proc2Dmem_data    (proc2Dmem_data)
    );

    stage_mem stage_mem_3 (
        // Inputs
        .ex_mem_reg     (ex_mem_reg_mult0),
        .Dmem2proc_data (mem2proc_data[`XLEN-1:0]), // for p3, we throw away the top 32 bits

        // Outputs
        .mem_packet        (mem_packet_mult0),
        .proc2Dmem_command (proc2Dmem_command),
        .proc2Dmem_size    (proc2Dmem_size),
        .proc2Dmem_addr    (proc2Dmem_addr),
        .proc2Dmem_data    (proc2Dmem_data)
    );

    stage_mem stage_mem_4 (
        // Inputs
        .ex_mem_reg     (ex_mem_reg_mult1),
        .Dmem2proc_data (mem2proc_data[`XLEN-1:0]), // for p3, we throw away the top 32 bits

        // Outputs
        .mem_packet        (mem_packet_mult1),
        .proc2Dmem_command (proc2Dmem_command),
        .proc2Dmem_size    (proc2Dmem_size),
        .proc2Dmem_addr    (proc2Dmem_addr),
        .proc2Dmem_data    (proc2Dmem_data)
    );

    stage_mem stage_mem_5 (
        // Inputs
        .ex_mem_reg     (ex_mem_reg_branch),
        .Dmem2proc_data (mem2proc_data[`XLEN-1:0]), // for p3, we throw away the top 32 bits

        // Outputs
        .mem_packet        (mem_packet_branch),
        .proc2Dmem_command (proc2Dmem_command),
        .proc2Dmem_size    (proc2Dmem_size),
        .proc2Dmem_addr    (proc2Dmem_addr),
        .proc2Dmem_data    (proc2Dmem_data)
    );

    cdb_processor cdb_0(
        .done_alu(done_alu),
	.done_mult0(done_mult0),
	.done_mult1(done_mult1),
	.done_load_store(done_load_store),
	.done_branch(done_branch),
	.register(cdb_register),
	.tag(cdb_val_res),
	.valid_cdb_out(valid_cdb_out)
    )

    //////////////////////////////////////////////////
    //                                              //
    //           MEM/WB Pipeline Register           //
    //                                              //
    //////////////////////////////////////////////////

    assign mem_wb_enable = 1'b1; // always enabled
    // synopsys sync_set_reset "reset"
    always_ff @(posedge clock) begin
        if (reset) begin
            mem_wb_inst_dbg <= `NOP; // debug output
            mem_wb_reg      <= 0;    // the defaults can all be zero!
        end else if (mem_wb_enable) begin
            mem_wb_inst_dbg <= ex_mem_inst_dbg; // debug output, just forwarded from EX
            mem_wb_reg_ls      <= mem_packet_ls;
            mem_wb_reg_alu      <= mem_packet_alu;
            mem_wb_reg_mt1      <= mem_packet_mult0;
            mem_wb_reg_mt2      <= mem_packet_mult1;
            mem_wb_reg_br      <= mem_packet_branch;
	    if(valid_cdb_out) begin
	        cdb_reg         <= cdb_register;
	        cdb_val         <= cdb_val_res;
	        value_rob       <= cdb_val_res;
	        value_tag       <= cdb_register;
		value_valid     <= 1;
	    end else begin
		value_valid     <= 0;    
	    end
            if(valid_cdb_out == 5'b00001) begin
		temp_mem_wb_reg <= mem_packet_alu;
	    end
            if(valid_cdb_out == 5'b00010) begin
		temp_mem_wb_reg <= mem_packet_mt1;
	    end
            if(valid_cdb_out == 5'b00100) begin
		temp_mem_wb_reg <= mem_packet_mt2;
	    end
            if(valid_cdb_out == 5'b01000) begin
		temp_mem_wb_reg <= mem_packet_ls;
	    end
            if(valid_cdb_out == 5'b10000) begin
		temp_mem_wb_reg <= mem_packet_branch;
	    end
        end
    end

    // debug outputs
    assign mem_wb_NPC_dbg   = mem_wb_reg.NPC;
    assign mem_wb_valid_dbg = mem_wb_reg.valid;

    //////////////////////////////////////////////////
    //                                              //
    //                  WB-Stage                    //
    //                                              //
    //////////////////////////////////////////////////
    
    stage_wb stage_wb_0 (
        // Input
        .mem_wb_reg (temp_mem_wb_reg), // doesn't use all of these

        // Outputs
        .wb_regfile_en   (wb_regfile_en),
        .wb_regfile_idx  (wb_regfile_idx),
        .wb_regfile_data (wb_regfile_data)
    );

    //////////////////////////////////////////////////
    //                                              //
    //               Pipeline Outputs               //
    //                                              //
    //////////////////////////////////////////////////

    assign pipeline_completed_insts = {3'b0, mem_wb_reg.valid}; // commit one valid instruction
    assign pipeline_error_status = mem_wb_reg.illegal        ? ILLEGAL_INST :
                                   mem_wb_reg.halt           ? HALTED_ON_WFI :
                                   (mem2proc_response==4'h0) ? LOAD_ACCESS_FAULT : NO_ERROR;

    assign pipeline_commit_wr_en   = wb_regfile_en;
    assign pipeline_commit_wr_idx  = wb_regfile_idx;
    assign pipeline_commit_wr_data = wb_regfile_data;
    assign pipeline_commit_NPC     = mem_wb_reg.NPC;

endmodule // pipeline
