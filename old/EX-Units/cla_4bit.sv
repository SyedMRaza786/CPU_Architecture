/*
 * 2 stage pipelined 4-bit carry lookahead adder module
 * for fast 32-bit multiplication
 */
module carry_lookahead_adder_4bit (
  input logic clk,
  input logic reset,
  input logic [3:0] a,
  input logic [3:0] b,
  input logic carry_in,
  output logic [3:0] partial_sum,
  output logic carry_out,
  output logic done
);

  logic [3:0] g, p;
  logic [4:0] carry;

  always_comb begin
    g = a & b;
    p = a ^ b;
    carry[0] = carry_in;
    carry[1] = g[0] | (p[0] & carry[0]);
    carry[2] = g[1] | (p[1] & carry[1]);
    carry[3] = g[2] | (p[2] & carry[2]);
    carry[4] = g[3] | (p[3] & carry[3]);
    carry_out = carry[4];
    partial_sum = p ^ carry[3:0];
  end

  always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
      done <= 1'b0;
    end else begin
      done <= 1'b1;
    end
  end

endmodule