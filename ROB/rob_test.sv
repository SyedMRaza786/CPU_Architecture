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

module testbench;
   
    logic              clock, reset, valid, commit;       
    logic [2:0]        opcode;    
    logic [31:0]       ROB_number;
    logic [4:0]        input_reg_1, input_reg_2, dest_reg;  
    logic [4:0]        done_signal;
    logic [`XLEN-1:0]  value;


    logic buffer_full, buffer_completed;
    logic[3:0]       head;
    logic[3:0]       tail;
    logic[2:0]       opcodes[7:0];
    logic[4:0]       input_reg_1s[7:0];
    logic[4:0]       input_reg_2s[7:0];
    logic[4:0]       Rs[7:0];
    logic[31:0]      Vs[7:0];

    logic correct;
    rob rob0 (
	    .clock(clock), .reset(reset), .valid(valid), 
        .opcode(opcode), .input_reg_1(input_reg_1),
        .input_reg_2(input_reg_2), .dest_reg(dest_reg), 
        .commit(commit), .value(value), .buffer_full(buffer_full),
        .buffer_completed(buffer_completed), .head(head), 
        .tail(tail), .opcodes(opcodes), .input_reg_1s(input_reg_1s), 
        .input_reg_2s(input_reg_2s), .Rs(Rs), .Vs(Vs)
    );

    
    always begin
        #(10.0/2.0);
        clock = ~clock;
    end

    
    always @(correct) begin
        #2
        if(!correct) begin
            $display("@@@ Incorrect at time %4.0f", $time);
	        for(int i = 0; i < 8; i++) begin
		        $display("head:%d, tail:%d, opcode:%b, input_reg_1:%b, input_reg_2:%b, R:%b, V:%d", head, tail, opcodes[i],
                 input_reg_1s[i], input_reg_2s[i], Rs[i], Vs[i]);
            end 
     
            $finish;
        end
    end

    initial begin
	
	reset = 1;
    clock = 0;
    valid = 0;
	commit = 0;
	#10;
    if(!(buffer_full == 0 && buffer_completed == 0 && head == 0 && 
    tail ==0 && opcodes.or() == 0 && input_reg_1s.or() == 0 && 
    input_reg_2s.or() == 0 && Rs.or() == 0 && 
    Vs.or() == 0)) correct = 0;
	
    
    for(int i = 0; i < 8; i++) begin
        $display("head:%d, tail:%d, opcode:%b, input_reg_1:%b, input_reg_2:%b, R:%b, V:%d", head, tail, 
        opcodes[i], input_reg_1s[i], input_reg_2s[i], 
        Rs[i], Vs[i]);
    end 
	

    reset = 0;
    valid = 1;
    opcode = `LD; 
	input_reg_1 = `r1;
	input_reg_2 =  0;
    dest_reg    = `f1;
    #10;
    if(!(buffer_full == 0 && buffer_completed == 0 && head == 1 && 
      tail == 1 && opcodes[0] == `LD && input_reg_1s[0] == input_reg_1 && 
      input_reg_2s[0] == input_reg_2 && 
      Rs[0] == dest_reg && Vs[0] == 0)) correct = 0;
	
    
    for(int i = 0; i < 8; i++) begin
        $display("head:%d, tail:%d, opcode:%b, input_reg_1:%b, input_reg_2:%b,  R:%b, V:%d", head, tail, 
        opcodes[i], input_reg_1s[i], input_reg_2s[i], 
        Rs[i], Vs[i]);
    end 

	input_reg_1 = `f0;
	input_reg_2 = `f1;
    dest_reg    = `f2;
	opcode = `FP; 
    
	#10;
    if(!(buffer_full == 0 && buffer_completed == 0 && head == 1 &&
        tail == 2 && opcodes[1] == `FP && input_reg_1s[1] == input_reg_1 &&
        input_reg_2s[1] == input_reg_2 &&
        Rs[1] == dest_reg && Vs[1] == 0)) correct = 0;
                               
      
      for(int i = 0; i < 8; i++) begin
          $display("head:%d, tail:%d, opcode:%b, input_reg_1:%b, input_reg_2:%b, R:%b, V:%d", head, tail, 
          opcodes[i], input_reg_1s[i], input_reg_2s[i], Rs[i], Vs[i]);
     end   


	input_reg_1 = `f2;
	input_reg_2 = 0;
    dest_reg = `r1;
	opcode = `ST;
    
	#10;
    if(!(buffer_full == 0 && buffer_completed == 0 && head == 1 &&
       tail == 3 && opcodes[2] == `ST && input_reg_1s[2] == input_reg_1 &&
       input_reg_2s[2] == input_reg_2 && 
       Rs[2] == dest_reg && Vs[2] == 0)) correct = 0;
                              
     
     for(int i = 0; i < 8; i++) begin
         $display("head:%d, tail:%d, opcode:%b, input_reg_1:%b, input_reg_2:%b, R:%b, V:%d", head, tail, 
         opcodes[i], input_reg_1s[i], input_reg_2s[i], Rs[i], Vs[i]);
     end   
    #20; 
    $display("@@@ PASSED");
    $finish;
    end
endmodule
