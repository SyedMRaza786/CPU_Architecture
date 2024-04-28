module opcode_determiner(
    input clock,
    input reset,
    input valid,
    input IF_ID_PACKET if_id_reg,
    output IF_ID_PACKET dispatch_packet,
    output opcode


);

    always_comb begin
	dispatch_packet = if_id_reg;
        opcode          = 3'b111;
        if(valid) begin
	    casez (if_id_reg.inst)
		`RV32_SLTI, `RV32_SLTIU, `RV32_ANDI, `RV32_ORI,
		`RV32_XORI, `RV32_SLLI,  `RV32_SRLI, `RV32_SRAI,
		`RV32_ADD,  `RV32_SUB,	 `RV32_SLT,  `RV32_SLTU,
		`RV32_AND,  `RV32_OR,	 `RV32_XOR,  `RV32_SLL,
		`RV32_SRL,  `RV32_SRA: begin
		    opcode = 3'b000;

		end
		`RV32_MUL, `RV32_MULH, `RV32_MULHSU, `RV32_MULHU: begin
		    opcode = 3'b001;
	
	
		end
		`RV32_BEQ, `RV32_BNE, `RV32_BLT, `RV32_BGE,
                `RV32_BLTU, `RV32_BGEU, `RV32_JALR, `RV32_JAL: begin
		    opcode = 3'b010;
	
		end
		`RV32_LB, `RV32_LH, `RV32_LW,
                `RV32_LBU, `RV32_LHU: begin
		    opcode = 3'b011;
		end
		`RV32_SB, `RV32_SH, `RV32_SW: begin
		    opcode = 3'b100;
		end
	    endcase
	end





    end
endmodule
