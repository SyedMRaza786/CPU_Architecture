// This module implements a 64-bit multiplication using a serial multiplication algorithm.
//
// Inputs:
//        clk - Clock signal
//        reset - Asynchronous reset signal
//        multiplier - 32-bit operand
//        multiplicand - 32-bit operand
//        start - Control signal to start multiplication
//
// Outputs:
//        product - 64-bit product of the multiplication
//        done - Signal indicating completion of multiplication
//
// Description:
// When 'start' is asserted, the multiplication process begins; 'done' is asserted once the process is complete,
// and the product is stored in `product`.
// The multiplication is performed serially, processing one bit of the multiplier per clock cycle.


`timescale 1ns / 100ps

module mul(
    input logic        clk,
    input logic        reset,
    input logic [31:0] multiplier,
    input logic [31:0] multiplicand,
    input logic        start,
    output logic [63:0] product,
    output logic       done
);

    logic [63:0] product_reg;
    logic [63:0] multiplicand_reg;
    logic [31:0] bit_pos;

    always_ff @(posedge clk or negedge reset) begin
      if (!reset) begin
          product_reg <= 64'b0;
          multiplicand_reg <= 64'b0;
          bit_pos <= 32'b0;
          done <= 1'b0;
      end else if (start && !done) begin
          product_reg <= {32'b0, multiplier};
          multiplicand_reg <= {32'b0, multiplicand};
          bit_pos <= 32'd0;
          done <= 1'b0;
      end else if (bit_pos < 32 && !done) begin
          if (product_reg[0]) begin
              product_reg <= product_reg + (multiplicand_reg << bit_pos);
          end
          product_reg <= product_reg >> 1;
          bit_pos <= bit_pos + 1;
      end else if (bit_pos == 32) begin
          done <= 1'b1;
      end
    end

    assign product = product_reg;
endmodule

module multiplier(
    input logic clk,
    input logic reset,
    input logic [31:0] multiplier,
    input logic [31:0] multiplicand,
    input logic start,
    input logic [1:0] mode, // 0: MULH, 1: MULHU, 2: MULHSU
    output logic [31:0] high_product,
    output logic done
);

    logic [63:0] product_reg;

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            product_reg <= 64'b0;
            done <= 1'b0;
        end else if (start) begin
            done <= 1'b0;
            case (mode)
                0: begin: MULH
                    product_reg <= $signed(multiplier) * $signed(multiplicand);
                end
                1: begin: MULHU
                    product_reg <= $unsigned({32'b0, multiplier}) * $unsigned({32'b0, multiplicand});
                end
                2: begin: MULHSU
                    product_reg <= $signed(multiplier) * $signed({{32{1'b0}}, multiplicand});
                end
            endcase
                done <= 1'b1;
        end
    end

    always_comb begin
        case (mode)
          	// Extract the high 32 bits for signed modes
            0, 2: high_product = product_reg[63:32];
	        // Extract the high 32 bits for unsigned mode
            1: high_product = product_reg[63:32];
        endcase
    end

endmodule
