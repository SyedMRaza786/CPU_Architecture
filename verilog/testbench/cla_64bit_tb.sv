module carry_lookahead_adder_64bit_tb;

  logic clk;
  logic reset;
  logic [63:0] a;
  logic [63:0] b;
  logic carry_in;
  logic [63:0] sum;
  logic carry_out;
  logic done;

  carry_lookahead_adder_64bit dut (
    .clk(clk),
    .reset(reset),
    .a(a),
    .b(b),
    .carry_in(carry_in),
    .sum(sum),
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
    reset = 1'b0;
    a = 64'h0;
    b = 64'h0;
    carry_in = 1'b0;

    #10;
    reset = 1'b1;

    a = 64'h1234_5678_9ABC_DEF0;
    b = 64'h0FED_CBA9_8765_4321;
    carry_in = 1'b0;
    #10;
    wait(done);
    #10;
    $display("Test case 1:");
    $display("a        = %b", a);
    $display("b        = %b", b);
    $display("carry_in = %b", carry_in);
    $display("sum      = %b", sum);
    $display("carry_out= %b", carry_out);
    assert(sum === 64'h2222_2222_2222_2211) else $error("Test case 1 sum failed"); 
    assert(carry_out === 1'b0)
      else $error("Test case 1 failed");

    // Test case 2: Addition with carry
    a = 64'hFFFF_FFFF_FFFF_FFFF;
    b = 64'h0000_0000_0000_0001;
    carry_in = 1'b0;
    #10;
    wait(done);
    #10;
    $display("Test case 2:");
    $display("a        = %b", a);
    $display("b        = %b", b);
    $display("carry_in = %b", carry_in);
    $display("sum      = %b", sum);
    $display("carry_out= %b", carry_out);
    assert(sum === 64'h0000_0000_0000_0000) else $error("Test case 2 sum failed");
    assert(carry_out === 1'b1) else $error("Test case 2 carry_out failed");

    // Test case 3: Addition with carry_in set
    a = 64'hFFFF_FFFF_FFFF_FFFF;
    b = 64'hFFFF_FFFF_FFFF_FFFF;
    carry_in = 1'b1;
    #10;
    wait(done);
    #10;
    $display("Test case 3:");
    $display("a        = %b", a);
    $display("b        = %b", b);
    $display("carry_in = %b", carry_in);
    $display("sum      = %b", sum);
    $display("carry_out= %b", carry_out);
    assert(sum === 64'hFFFF_FFFF_FFFF_FFFF) else $error("Test case 3 sum failed");
    assert(carry_out === 1'b1) else $error("Test case 3 failed");

    $finish;
  end

endmodule