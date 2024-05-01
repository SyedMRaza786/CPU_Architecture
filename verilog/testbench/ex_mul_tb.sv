`timescale 1ns / 100ps
import test_utils::*;

module test_mulhu_mulhsu;
  // Inputs
  reg clk;
  reg reset;
  reg [31:0] multiplier;
  reg [31:0] multiplicand;
  reg start;
  reg [1:0] mode;

  logic [31:0] high_product;
  logic done;

  multiplier uut (
    .clk(clk),
    .reset(reset),
    .multiplier(multiplier),
    .multiplicand(multiplicand),
    .start(start),
    .mode(mode),
    .high_product(high_product),
    .done(done)
  );


  always #5 clk = ~clk;

  initial begin
    clk = 0;
    reset = 0;
    multiplier = 0;
    multiplicand = 0;
    start = 0;
    mode = 0;

    #10;
    reset = 1;
    #10;

    test_mulhu();
    test_mulhsu();

    $finish;
  end

  task test_mulhu;
    mode = 1;

    // Max unsigned values
    multiplier = 32'hFFFF_FFFF;
    multiplicand = 32'hFFFF_FFFF;
    start = 1; #10; start = 0; wait(done);
    #10;
    if (high_product !== 32'hFFFF_FFFE) begin
      $display("Test Failed for MULHU max values: Expected 0xfffffffe, Got %h", high_product);
    end else begin
      $display("Test Passed for MULHU max values.");
    end

    // Zero test
    multiplier = 32'h0000_0000;
    multiplicand = 32'hFFFF_FFFF;
    start = 1; #10; start = 0; wait(done);
    #10;
    if (high_product !== 32'h0000_0000) begin
      $display("Test Failed for MULHU zero: Expected 0, Got %h", high_product);
    end else begin
      $display("Test Passed for MULHU zero.");
    end

    // Multiplier or multiplicand is one
    multiplier = 32'h0000_0001;
    multiplicand = 32'hFFFF_FFFF;
    start = 1; #10; start = 0; wait(done);
    #10;
    if (high_product !== 32'h0000_0000) begin
      $display("Test Failed for MULHU multiplier is one: Expected 0, Got %h", high_product);
    end else begin
      $display("Test Passed for MULHU multiplier is one.");
    end

    // Odd & even numbers
    multiplier = 32'h1234_5678;
    multiplicand = 32'h9ABC_DEF0;
    start = 1; #10; start = 0; wait(done);
    #10;
    if (high_product !== 32'h0B00_EA4E) begin
      $display("Test Failed for MULHU odd & even numbers: Expected 0x0B00_EA4E, Got %h", high_product);
    end else begin
      $display("Test Passed for MULHU odd & even numbers.");
    end

    // Non-power of 2 values
    multiplier = 32'h1234_5678;
    multiplicand = 32'h1234_5678;
    start = 1; #10; start = 0; wait(done);
    #10;
    if (high_product !== 32'h014B_66DC) begin
      $display("Test Failed for MULHU non-power of 2 values: Expected 0x014B_66DC, Got %h", high_product);
    end else begin
      $display("Test Passed for MULHU non-power of 2 values.");
    end

    // Repeated multiplications
    multiplier = 32'hFFFF_FFFF;
    multiplicand = 32'hFFFF_FFFF;
    start = 1; #10; start = 0; wait(done);
    #10;
    if (high_product !== 32'hFFFF_FFFE) begin
      $display("Test Failed for MULHU repeated multiplication 1: Expected 0xFFFF_FFFE, Got %h", high_product);
    end else begin
      $display("Test Passed for MULHU repeated multiplication 1.");
    end

    start = 1; #10; start = 0; wait(done);
    #10;
    if (high_product !== 32'hFFFF_FFFE) begin
      $display("Test Failed for MULHU repeated multiplication 2: Expected 0xFFFF_FFFE, Got %h", high_product);
    end else begin
      $display("Test Passed for MULHU repeated multiplication 2.");
    end
  endtask

  task test_mulhsu;
    mode = 2;

    // Max signed by max unsigned
    multiplier = 32'h7FFF_FFFF;
    multiplicand = 32'hFFFF_FFFF;
    start = 1; #10; start = 0; wait(done);
    #10;
    if (high_product !== 32'h7FFF_FFFE) begin
      $display("Test Failed for MULHSU max signed by max unsigned: Expected 0x7FFFFFFE, Got %h", high_product);
    end else begin
      $display("Test Passed for MULHSU max signed by max unsigned.");
    end

    // Negative signed by max unsigned
    multiplier = 32'h8000_0000; // -2147483648 in two's complement
    multiplicand = 32'hFFFF_FFFF; // Max unsigned
    start = 1; #10; start = 0; wait(done);
    #10;
    if (high_product !== 32'h8000_0000) begin
      $display("Test Failed for MULHSU negative by max unsigned: Expected 0x8000_0000, Got %h", high_product);
    end else begin
      $display("Test Passed for MULHSU negative by max unsigned.");
    end

    // Mixed sign zero effect
    multiplier = 32'hFFFF_FFFF; // -1 in two's complement, signed
    multiplicand = 32'h0000_0000; // Zero
    start = 1; #10; start = 0; wait(done);
    #10;
    if (high_product !== 32'h0000_0000) begin
      $display("Test Failed for MULHSU mixed zero: Expected 0, Got %h", high_product);
    end else begin
      $display("Test Passed for MULHSU mixed zero.");
    end

    // Multiplying 0x80000000 by 0x80000000
    multiplier = 32'h8000_0000;
    multiplicand = 32'h8000_0000;
    start = 1; #10; start = 0; wait(done);
    #10;
    if (high_product !== 32'hc000_0000) begin
      $display("Test Failed for MULHSU 0x80000000 by 0x80000000: Expected 0xc0000000, Got %h", high_product);
    end else begin
      $display("Test Passed for MULHSU 0x80000000 by 0x80000000.");
    end

    // Multiplying 0x7FFFFFFF by 0x7FFFFFFF
    multiplier = 32'h7FFF_FFFF;
    multiplicand = 32'h7FFF_FFFF;
    start = 1; #10; start = 0; wait(done);
    #10;
    if (high_product !== 32'h3FFF_FFFF) begin
      $display("Test Failed for MULHSU 0x7FFFFFFF by 0x7FFFFFFF: Expected 0x3FFF_FFFF, Got %h", high_product);
    end else begin
      $display("Test Passed for MULHSU 0x7FFFFFFF by 0x7FFFFFFF.");
    end
  endtask
endmodule