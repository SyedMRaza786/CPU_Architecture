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


module carry_lookahead_adder_64bit (
  input logic clk,
  input logic reset,
  input logic [63:0] a,
  input logic [63:0] b,
  input logic carry_in,
  output logic [63:0] sum,
  output logic carry_out,
  output logic done
);

  logic [15:0] carry;
  logic [15:0] done_signals;

  genvar i;
  generate
    for (i = 0; i < 16; i++) begin : CLA_BLOCKS
      carry_lookahead_adder_4bit cla_block(
        .clk(clk),
        .reset(reset),
        .a(a[4*i+3 : 4*i]),
        .b(b[4*i+3 : 4*i]),
        .carry_in(i == 0 ? carry_in : carry[i-1]),
        .partial_sum(sum[4*i+3 : 4*i]),
        .carry_out(carry[i]),
        .done(done_signals[i])
      );
    end
  endgenerate

  always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
      carry_out <= 1'b0;
      done <= 1'b0;
    end else begin
      carry_out <= carry[15];
      done <= &done_signals;
    end
  end

endmodule