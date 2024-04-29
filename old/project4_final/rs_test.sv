`define ALU 3'b001
`define LD  3'b010
`define ST  3'b011
`define FP  3'b100
`define f0  4'b0001
`define f1  4'b0010
`define f2  4'b0011
`define r1  4'b0100


module testbench;
   
    logic             clock, reset, rs_valid;       // only go to next PC when true
    logic [2:0]       opcode;    
    logic [31:0]      ROB_number;
    logic [4:0]       input_reg_1, input_reg_2, dest_reg;  
    logic [4:0]       done_signal;
    logic [`XLEN-1:0] value_1, value_2;

    integer i;

    logic [2:0]       busy_signal;
    logic [6:0]       out_opcode[4:0];
    logic [31:0]      T[4:0], T1[4:0], T2[4:0];
    logic [`XLEN-1:0] V1[4:0], V2[4:0];
    logic             correct;
    rs rs0 (
	.clock, .reset, .rs_valid, 
        .opcode, 
        .ROB_number,
        .input_reg_1, .input_reg_2, .dest_reg,
        .done_signal,
        .busy_signal, .out_opcode,
        .T, .T1, .T2, .V1, .V2
    );

    
    always begin
        #(10.0/2.0);
        clock = ~clock;
    end

    
    always @(correct) begin
        #2
        if(!correct) begin
            $display("@@@ Incorrect at time %4.0f", $time);
            $display("@@@ gnt=%b, en=%b, req=%b, req_up=%b", gnt, en, req, req_up);
            $display("@@@ expected result: gnt=%b, req_up=%b", tb_gnt, req_up);
            $finish;
        end
    end

    initial begin
	
	reset = 1;
        clock = 0;
        rs_valid = 1;
	done_signal = 0;
	if(!(busy_signal == 0 && out_opcode == 0 && T == 0 && T1 == 0 && T2 == 0 && V1 == 0 && V2 == 0)) correct = 1;
        #10

	reset = 0;
	
        opcode = LD; 
        ROB_number = 1;
	input_reg_1 = r1;
	input_reg_2 = 0;
        dest_reg = f1;
	value_1 = `XLEN'd4;
	value_2 = `XLEN'd6;
        if(!(busy_signal == 5'b00010 && out_opcode[1] == LD && T == 32'b1 && T1 == 0 && T2 == 0 && V1 == `XLEN'd4 && V2 == `XLEN'd6)) correct = 1;
                             // ldf X(r1),f1
	#10;
  

	input_reg_1 = f0;
	input_reg_2 = f1;
        dest_reg = f2;
	value_1 = `XLEN'd8;
	value_2 = `XLEN'd10;
        
	opcode = FP; ROB_number = 2; // mulf f0,f1,f2
	if(!(busy_signal == 5'bx1x1x && out_opcode[3] == FP && T == 32'd2 && T1 == 0 && T2 == 32'b1 && V1 == `XLEN'd8 && V2 == `XLEN'd10)) correct = 1;
	#10;

	input_reg_1 = f2;
	input_reg_2 = 0;
        dest_reg = r1;
	value_1 = `XLEN'd12;
	value_2 = `XLEN'd14;
	opcode = ST; ROB_number = 3; // stf f2,Z(r1)
	if(!(busy_signal == 5'b01100 && out_opcode[2] == ST && T == 32'd3 && T1 == 32'd2 && T2 == 0 && V1 == 0 && V2 == `XLEN'd14)) correct = 1;
	#10;
/*
	input_reg_1 = r1;
	input_reg_2 = 0;
        dest_reg = r1;
	value_1 = `XLEN'd12;
	value_2 = `XLEN'd14;
	map_table[input_reg 1] = 4; // addi r1,4,r1
	opcode = FP; V1 = f0; ROB_number = 4; map_table[input_reg 1] = 4; V2 = X[1]; // ldf X(r1),f1
	#10;

	opcode = FP; T1 = 4; T2 = 4; ROB_number = 5; // mulf f0,f1,f2
	#10;	
	opcode = ST; ROB_number = 6; T2 = 5; map_table[input_reg 2] = 4; V1 = 4; // stf f2,Z(r1)


        $monitor("Time:%4.0f req:%b en:%b gnt:%b req_up:%b", $time, req, en, gnt, req_up);
        req = 8'b0;
        en = 1;
        //testing all possible combinations for 8 bit selector as well as req_up signal
        for (i = 0; i<=8'b1111_1111; i = i + 1) begin
            #5 req = i;
	end
        #5 en = 0;
        #5 req = 8'b11111111;
*/
        $display("@@@ PASSED");
        $finish;
    end
endmodule
