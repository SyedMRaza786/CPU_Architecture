module fp_adder_tb;

  logic          clk;
  logic          reset;
  logic [31:0]   op1;
  logic [31:0]   op2;
  logic          valid;
  logic [31:0]   result;
  logic          done;

  fp_adder dut (
    .clk(clk),
    .reset(reset),
    .op1(op1),
    .op2(op2),
    .valid(valid),
    .result(result),
    .done(done)
  );

  always begin
    #5 clk = ~clk;
  end

  initial begin
    clk = 0;
    reset = 0;
    op1 = 0;
    op2 = 0;
    valid = 0;

    // Reset the module
    #10 reset = 1;

    // Test case 1: Add two positive numbers
    #10 op1 = 32'h40200000; // 2.5 in IEEE 754 single precision
    op2 = 32'h40400000; // 3.0 in IEEE 754 single precision
    valid = 1;

    #10 valid = 0;
    wait(done);
    $display("Test case 1: %h + %h = %h", op1, op2, result);
    assert(result === 32'h40b00000) else $error("Test case 1 failed");

    // Test case 2: Add a positive and a negative number
    #10 op1 = 32'h40200000; // 2.5 in IEEE 754 single precision
    op2 = 32'hC0400000; // -3.0 in IEEE 754 single precision
    valid = 1;

    #10 valid = 0;
    wait(done);
    $display("Test case 2: %h + %h = %h", op1, op2, result);
    assert(result === 32'hbf000000) else $error("Test case 2 failed");

    // Test case 3: Add two negative numbers
    #10 op1 = 32'hC0200000; // -2.5 in IEEE 754 single precision
    op2 = 32'hC0400000; // -3.0 in IEEE 754 single precision
    valid = 1;

    #10 valid = 0;
    wait(done);
    $display("Test case 3: %h + %h = %h", op1, op2, result);
    assert(result === 32'hc0b00000) else $error("Test case 3 failed");

    // Test case 4: Add a number to infinity
    #10 op1 = 32'h40200000; // 2.5 in IEEE 754 single precision
    op2 = 32'h7F800000; // +infinity in IEEE 754 single precision
    valid = 1;

    #10 valid = 0;
    wait(done);
    $display("Test case 4: %h + %h = %h", op1, op2, result);
    assert(result === 32'h7f800000) else $error("Test case 4 failed");

    #10 $finish;
  end

endmodule