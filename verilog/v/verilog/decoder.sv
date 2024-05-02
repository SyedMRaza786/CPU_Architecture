
// The decoder, copied from p3/stage_id.sv without changes

`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

// Decode an instruction: generate useful datapath control signals by matching the RISC-V ISA
// This module is purely combinational
module decoder (
    input INST  inst,
    input logic valid, // when low, ignore inst. Output will look like a NOP

    output logic [2:0] opcode
);
    logic illegal;
    // Note: I recommend using an IDE's code folding feature on this block
    always_comb begin



        if (valid) begin
            casez (inst)
                `RV32_LUI: begin
                    opcode = 3'b011;
                end
                `RV32_AUIPC: begin
                    opcode = 3'b100;
                end
                `RV32_JAL: begin
		    opcode = 3'b100;
                end
                `RV32_JALR: begin
		    opcode = 3'b100;
                end
                `RV32_BEQ, `RV32_BNE, `RV32_BLT, `RV32_BGE,
                `RV32_BLTU, `RV32_BGEU: begin
		    opcode = 3'b100;
                end
                `RV32_LB, `RV32_LH, `RV32_LW,
                `RV32_LBU, `RV32_LHU: begin
		    opcode = 3'b011;
                end
                `RV32_SB, `RV32_SH, `RV32_SW: begin
		    opcode = 3'b011;
                end
                `RV32_ADDI: begin
		    opcode = 3'b001;
                end
                `RV32_SLTI: begin
		    opcode = 3'b001;
                end
                `RV32_SLTIU: begin
		    opcode = 3'b001;
                end
                `RV32_ANDI: begin
		    opcode = 3'b001;
                end
                `RV32_ORI: begin
		    opcode = 3'b001;
                end
                `RV32_XORI: begin
		    opcode = 3'b001;
                end
                `RV32_SLLI: begin
		    opcode = 3'b001;
                end
                `RV32_SRLI: begin
		    opcode = 3'b001;
                end
                `RV32_SRAI: begin
		    opcode = 3'b001;
                end
                `RV32_ADD: begin
                    opcode = 3'b001;
                end
                `RV32_SUB: begin
		    opcode = 3'b001;
                end
                `RV32_SLT: begin
		    opcode = 3'b001;
                end
                `RV32_SLTU: begin
		    opcode = 3'b001;
                end
                `RV32_AND: begin
		    opcode = 3'b001;
                end
                `RV32_OR: begin
		    opcode = 3'b001;
                end
                `RV32_XOR: begin
		    opcode = 3'b001;
                end
                `RV32_SLL: begin
		    opcode = 3'b001;
                end
                `RV32_SRL: begin
		    opcode = 3'b001;
                end
                `RV32_SRA: begin
		    opcode = 3'b001;
                end
                `RV32_MUL: begin
		    opcode = 3'b010;
                end
                `RV32_MULH: begin
		    opcode = 3'b010;
                end
                `RV32_MULHSU: begin
		    opcode = 3'b010;
                end
                `RV32_MULHU: begin
		    opcode = 3'b010;
                end
                `RV32_CSRRW, `RV32_CSRRS, `RV32_CSRRC: begin
                    opcode = 3'b100;
                end
                `WFI: begin
                    opcode = 3'b100;
                end
                default: begin
                    illegal = `TRUE;
                end
        endcase // casez (inst)
        end // if (valid)
    end // always

endmodule // decoder
