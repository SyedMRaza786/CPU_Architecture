module carry_lookahead_adder_4bit_tb;

logic clk;
logic rst_n;
logic [3:0] a;
logic [3:0] b;
logic carry_in;
logic [3:0] partial_sum;
logic carry_out;
logic done;

carry_lookahead_adder_4bit dut (
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .carry_in(carry_in),
    .partial_sum(partial_sum),
	.carry_out(carry_out),
  	.done(done)
);

always begin
    clk = 1'b0;
    #5;
    clk = 1'b1;
    #5;
end

initial begin
    rst_n = 1'b0;
    #10;
    rst_n = 1'b1;
end

initial begin
    // Test case 1: All bits set
    a = 4'b1111;
    b = 4'b1111;
    carry_in = 1'b1;
    #20;
    $display("Test case 1: All bits set");
    $display("a = %b, b = %b, carry_in = %b", a, b, carry_in);
  	wait(done);
    $display("partial_sum = %b, carry_out = %b", partial_sum, carry_out);
	assert(partial_sum === 4'b1111) else $error("Test case 1 failed: partial_sum mismatch");
  	assert(carry_out === 1'b1) else $error("Test case 1 failed: carry_out mismatch");

    // Test case 2: Alternating bits
  	a = 4'b1010;
    b = 4'b0101;
    carry_in = 1'b0;
    #20;
    $display("Test case 2: Alternating bits");
    $display("a = %b, b = %b, carry_in = %b", a, b, carry_in);
  	wait(done);
    $display("partial_sum = %b, carry_out = %b", partial_sum, carry_out);
  	assert(partial_sum === 4'b1111) else $error("Test case 2 failed: partial_sum mismatch");
  	assert(carry_out === 1'b0) else $error("Test case 2 failed: carry_out mismatch");

    // Test case 3: Maximum carry propagation
    a = 4'b1111;
    b = 4'b0001;
    carry_in = 1'b0;
    #20;
    $display("Test case 3: Maximum carry propagation");
    $display("a = %b, b = %b, carry_in = %b", a, b, carry_in);
   	wait(done);
    $display("partial_sum = %b, carry_out = %b", partial_sum, carry_out);
  	assert(partial_sum === 4'b0000) else $error("Test case 3 failed: partial_sum mismatch");
  	assert(carry_out === 1'b1) else $error("Test case 3 failed: carry_out mismatch");

    $finish;
end

endmodule