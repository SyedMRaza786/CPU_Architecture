`define ALU 3'b001
`define LD  3'b010
`define ST  3'b011
`define FP  3'b100
`define f0  4'b0001
`define f1  4'b0010
`define f2  4'b0011
`define r1  4'b0100
`define XLEN 32
`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"

module testbench;
   
    logic              clock, reset, rob_initial_valid, rob_valid, rs_valid, commit_rob;       
    logic [2:0]        dispatch_opcode;    
    logic [31:0]       ROB_number;
    logic [4:0]        input_1, input_2, dest_reg;  
    logic [4:0]        done_signal;
    logic [`XLEN-1:0]  rs_V1, rs_V2, value_rob;
    logic correct = 1;


    ROB                rob_table;
    RS                 rs_table;
    pipeline pp0(
	.clock(clock), .reset(reset), .rob_initial_valid(rob_initial_valid),
	.rob_valid(rob_valid), .dispatch_opcode(dispatch_opcode), .input_1(input_1),
	.input_2(input_2), .dest_reg(dest_reg), .rs_done_signal(done_signal),
	.commit_rob(commit_rob), .value_rob(value_rob), .rs_valid(rs_valid), .rs_V1(rs_V1), .rs_V2(rs_V2),
	.rob_table(rob_table), .rs_table(rs_table) 
    );

    
    always begin
        #(10.0/2.0);
        clock = ~clock;
    end

   /* 
    always @(correct) begin
        #2
        if(!correct) begin
            $display("@@@ Incorrect at time %4.0f", $time);
		$display("Reset:%b Head:%d Tail:%d", reset, rob_table.head, rob_table.tail);
	        for(int i = 0; i < 8; i++) begin
		        $display("Opcode:%b Source1:%b Source2:%b Destination:%b R:%b V:%d", rob_table.opcodes[i], rob_table.input_reg_1s[i], rob_table.input_reg_2s[i], rob_table.dest_regs[i], rob_table.Rs[i], rob_table.Vs[i]);
		end 
		$display("Busy signal:%b", rs_table.busy_signal);
		for(int j = 0; j < 5; j++) begin
			$display("Opcode:%b T:%b T1:%b T2:%b V1:%b V2:%b", rs_table.out_opcode[j], rs_table.T[j], rs_table.T1[j], rs_table.T2[j], rs_table.V1[j], rs_table.V2[j]);
            	end 
		for(int j = 0; j < 4; j++) begin
			$display("Tag:%d",rs_table.map_table[j]);
            	end 
     
            $finish;
        end
    end
*/
    initial begin
	
	reset = 1;
    	clock = 0;
    	rs_valid = 0;
	done_signal = 0;
	rob_initial_valid = 0;
	rob_valid = 0;
	commit_rob = 0;
	#10;
    	if(rs_table.busy_signal != 0 || rs_table.out_opcode.or() != 0 || rs_table.T.or() != 0 || rs_table.T1.or() != 0 || rs_table.T2.or() != 0 || 
rs_table.V1.or() != 0 || rs_table.V2.or() != 0 || rs_table.map_table.or() != 0) correct = 0;
	$display("Reset:%b Head:%d Tail:%d", reset, rob_table.head, rob_table.tail);
	        for(int i = 0; i < 8; i++) begin
		        $display("Opcode:%b Source1:%b Source2:%b Destination:%b R:%b V:%d", rob_table.opcodes[i], rob_table.input_reg_1s[i], rob_table.input_reg_2s[i], rob_table.dest_regs[i], rob_table.Rs[i], rob_table.Vs[i]);
		end 
		$display("Busy signal:%b", rs_table.busy_signal);
		for(int j = 0; j < 5; j++) begin
			$display("Opcode:%b T:%b T1:%b T2:%b V1:%b V2:%b", rs_table.out_opcode[j], rs_table.T[j], rs_table.T1[j], rs_table.T2[j], rs_table.V1[j], rs_table.V2[j]);
            	end 
		for(int j = 0; j < 4; j++) begin
			$display("Tag:%d",rs_table.map_table[j]);
            	end 
    
    reset = 0;
    rob_initial_valid = 1;
    rob_valid = 1;
    dispatch_opcode = `LD;
    input_1 = `r1;
    input_2 = 0;
    dest_reg = `f1;
    rs_valid = 1;
    rs_V1 = 32'b1000;
    rs_V2 = 32'b10000;

    #10;
    if(rs_table.busy_signal != 00010 || rs_table.out_opcode[1] != `LD || rs_table.T[1] != 1 || rs_table.T1.or() != 0 || rs_table.T2.or() != 0 || rs_table.V1[1] != 32'b1000 || rs_table.V2[1] != 32'b10000 || rs_table.map_table[2] != 1) correct = 0;

	$display("Reset:%b Head:%d Tail:%d", reset, rob_table.head, rob_table.tail);
	        for(int i = 0; i < 8; i++) begin
		        $display("Opcode:%b Source1:%b Source2:%b Destination:%b R:%b V:%d", rob_table.opcodes[i], rob_table.input_reg_1s[i], rob_table.input_reg_2s[i], rob_table.dest_regs[i], rob_table.Rs[i], rob_table.Vs[i]);
		end 
		$display("Busy signal:%b", rs_table.busy_signal);
		for(int j = 0; j < 5; j++) begin
			$display("Opcode:%b T:%b T1:%b T2:%b V1:%b V2:%b", rs_table.out_opcode[j], rs_table.T[j], rs_table.T1[j], rs_table.T2[j], rs_table.V1[j], rs_table.V2[j]);
            	end 
		for(int j = 0; j < 4; j++) begin
			$display("Tag:%d",rs_table.map_table[j]);
            	end 
    
    reset = 0;
    rob_initial_valid = 1;
    rob_valid = 1;
    dispatch_opcode = `FP;
    input_1 = `f0;
    input_2 = `f1;
    dest_reg = `f2;
    rs_valid = 1;
    rs_V1 = 32'b10;
    rs_V2 = 32'b1000;

    #10;
    if(rs_table.busy_signal != 01010 || rs_table.out_opcode[3] != `FP || rs_table.T[3] != 2 || rs_table.T1[3] != 0 || rs_table.T2[3] != 2 || 
rs_table.V1[3] != 2 || rs_table.V2[3] != 0 || rs_table.map_table[2] != 2) correct = 0;

	$display("Reset:%b Head:%d Tail:%d", reset, rob_table.head, rob_table.tail);
	        for(int i = 0; i < 8; i++) begin
		        $display("Opcode:%b Source1:%b Source2:%b Destination:%b R:%b V:%d", rob_table.opcodes[i], rob_table.input_reg_1s[i], rob_table.input_reg_2s[i], rob_table.dest_regs[i], rob_table.Rs[i], rob_table.Vs[i]);
		end 
		$display("Busy signal:%b", rs_table.busy_signal);
		for(int j = 0; j < 5; j++) begin
			$display("Opcode:%b T:%b T1:%b T2:%b V1:%b V2:%b", rs_table.out_opcode[j], rs_table.T[j], rs_table.T1[j], rs_table.T2[j], rs_table.V1[j], rs_table.V2[j]);
            	end 
		for(int j = 0; j < 4; j++) begin
			$display("Tag:%d",rs_table.map_table[j]);
            	end 





    reset = 0;
    rob_initial_valid = 1;
    rob_valid = 1;
    dispatch_opcode = `ST;
    input_1 = `f2;
    input_2 = 0;
    dest_reg = `r1;
    commit_rob = 1;
    value_rob = 32'b1000000;
    rs_valid = 1;
    done_signal = 01000;
    rs_V1 = 32'b10;
    rs_V2 = 32'b10000;

    #10;
    if(rs_table.busy_signal != 01100 || rs_table.out_opcode[2] != `ST || rs_table.T[2] != 3 || rs_table.T1[2] != 2 || rs_table.T2[2] != 0 || 
rs_table.V1[2] != 0 || rs_table.V2[2] != 16 || rs_table.map_table[2] != 2) correct = 0;

	$display("Reset:%b Head:%d Tail:%d", reset, rob_table.head, rob_table.tail);
	        for(int i = 0; i < 8; i++) begin
		        $display("Opcode:%b Source1:%b Source2:%b Destination:%b R:%b V:%d", rob_table.opcodes[i], rob_table.input_reg_1s[i], rob_table.input_reg_2s[i], rob_table.dest_regs[i], rob_table.Rs[i], rob_table.Vs[i]);
		end 
		$display("Busy signal:%b", rs_table.busy_signal);
		for(int j = 0; j < 5; j++) begin
			$display("Opcode:%b T:%b T1:%b T2:%b V1:%b V2:%b", rs_table.out_opcode[j], rs_table.T[j], rs_table.T1[j], rs_table.T2[j], rs_table.V1[j], rs_table.V2[j]);
            	end 
		for(int j = 0; j < 4; j++) begin
			$display("Tag:%d",rs_table.map_table[j]);
            	end 


/*
#10;
    reset = 0;
    rob_initial_valid = 1;
    rob_valid = 1;
    dispatch_opcode = ;
    input_1 = ;
    input_2 = ;
    dest_reg = ;
    commit_rob = ;
    value_rob = ;
    rs_valid = ;
    rs_done_signal = ;
    rs_V1 = ;
    rs_V2 = ;

    #10;
    if(rs_table.busy_signal != 0 || rs_table.out_opcode.or() != 0 || rs_table.T.or() != 0 || rs_table.T1.or() != 0 || rs_table.T2.or() != 0 || 
rs_rable.V1.or() != 0 || rs_table.V2.or() != 0 || rs_table.map_table.or() != 0) correct = 0
#10;
	$display("Reset:%b Head:%d Tail:%d", reset, rob_table.head, rob_table.tail);
	        for(int i = 0; i < 8; i++) begin
		        $display("Opcode:%b Source1:%b Source2:%b Destination:%b R:%b V:%d", rob_table.opcodes[i], rob_table.input_reg_1s[i], rob_table.input_reg_2s[i], rob_table.dest_regs[i], rob_table.Rs[i], rob_table.Vs[i]);
		end 
		$display("Busy signal:%b", rs_table.busy_signal);
		for(int j = 0; i < 5; i++) begin
			$display("Opcode:%b T:%b T1:%b T2:%b V1:%b V2:%b", rs_table.out_opcode[j], rs_table.T[j], rs_table.T1[j], rs_table.T2[j], rs_table.V1[j], rs_table.V2[j]);
            	end 
		for(int j = 0; i < 4; i++) begin
			$display("Tag:%d",rs_table.map_table[i]);
            	end 




#10;
    reset = 0;
    rob_initial_valid = 1;
    rob_valid = 1;
    dispatch_opcode = ;
    input_1 = ;
    input_2 = ;
    dest_reg = ;
    commit_rob = ;
    value_rob = ;
    rs_valid = ;
    rs_done_signal = ;
    rs_V1 = ;
    rs_V2 = ;

    #10;
    if(rs_table.busy_signal != 0 || rs_table.out_opcode.or() != 0 || rs_table.T.or() != 0 || rs_table.T1.or() != 0 || rs_table.T2.or() != 0 || 
rs_rable.V1.or() != 0 || rs_table.V2.or() != 0 || rs_table.map_table.or() != 0) correct = 0
#10;
	$display("Reset:%b Head:%d Tail:%d", reset, rob_table.head, rob_table.tail);
	        for(int i = 0; i < 8; i++) begin
		        $display("Opcode:%b Source1:%b Source2:%b Destination:%b R:%b V:%d", rob_table.opcodes[i], rob_table.input_reg_1s[i], rob_table.input_reg_2s[i], rob_table.dest_regs[i], rob_table.Rs[i], rob_table.Vs[i]);
		end 
		$display("Busy signal:%b", rs_table.busy_signal);
		for(int j = 0; i < 5; i++) begin
			$display("Opcode:%b T:%b T1:%b T2:%b V1:%b V2:%b", rs_table.out_opcode[j], rs_table.T[j], rs_table.T1[j], rs_table.T2[j], rs_table.V1[j], rs_table.V2[j]);
            	end 
		for(int j = 0; i < 4; i++) begin
			$display("Tag:%d",rs_table.map_table[i]);
            	end 




#10;
    reset = 0;
    rob_initial_valid = 1;
    rob_valid = 1;
    dispatch_opcode = ;
    input_1 = ;
    input_2 = ;
    dest_reg = ;
    commit_rob = ;
    value_rob = ;
    rs_valid = ;
    rs_done_signal = ;
    rs_V1 = ;
    rs_V2 = ;

    #10;
    if(rs_table.busy_signal != 0 || rs_table.out_opcode.or() != 0 || rs_table.T.or() != 0 || rs_table.T1.or() != 0 || rs_table.T2.or() != 0 || 
rs_rable.V1.or() != 0 || rs_table.V2.or() != 0 || rs_table.map_table.or() != 0) correct = 0
#10;
	$display("Reset:%b Head:%d Tail:%d", reset, rob_table.head, rob_table.tail);
	        for(int i = 0; i < 8; i++) begin
		        $display("Opcode:%b Source1:%b Source2:%b Destination:%b R:%b V:%d", rob_table.opcodes[i], rob_table.input_reg_1s[i], rob_table.input_reg_2s[i], rob_table.dest_regs[i], rob_table.Rs[i], rob_table.Vs[i]);
		end 
		$display("Busy signal:%b", rs_table.busy_signal);
		for(int j = 0; i < 5; i++) begin
			$display("Opcode:%b T:%b T1:%b T2:%b V1:%b V2:%b", rs_table.out_opcode[j], rs_table.T[j], rs_table.T1[j], rs_table.T2[j], rs_table.V1[j], rs_table.V2[j]);
            	end 
		for(int j = 0; i < 4; i++) begin
			$display("Tag:%d",rs_table.map_table[i]);
            	end 
*/
    #20; 
    $display("@@@ PASSED");
    $finish;
    end
endmodule
