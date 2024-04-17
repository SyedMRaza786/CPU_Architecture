/*
 * 2 stage pipelined 4-bit carry lookahead adder module
 * for fast 32-bit multiplication
 */
module four_bit_carry_lookahead_adder(
  input logic           clk,
  input logic           reset,
  input logic [3:0]     a,
  input logic [3:0]     b,
  input logic           carry_in,

  output logic [3:0]    partial_sum,
  output logic          carry_out,
  output logic          done
);

  logic [3:0] g, p;
  logic [4:0] carry;
  logic [3:0] sum_intermediate;

  always_comb begin
    g = a & b;
    p = a ^ b;
    carry[0] = carry_in;
    carry[1] = g[0] | (p[0] & carry_in);
    carry[2] = g[1] | (p[1] & carry[1]);
    carry[3] = g[2] | (p[2] & carry[2]);
    carry[4] = g[3] | (p[3] & carry[3]);
    sum_intermediate = p ^ carry[3:0];
  end

  // pipelined setting of partial sums & carry out
  always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
      partial_sum <= 4'b0;
      carry_out <= 1'b0;
      done <= 1'b0;
    end else begin
      partial_sum <= sum_intermediate;
      carry_out <= carry[4];
      done <= 1'b1;
    end
  end
endmodule