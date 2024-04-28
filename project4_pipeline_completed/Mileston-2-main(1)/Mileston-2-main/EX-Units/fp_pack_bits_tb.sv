///
/// Testbench for `pack_bits` module
///
module pack_bits_tb;

  logic [23:0] n_m;
  logic [9:0]  n_e;
  logic        n_s;

  logic [31:0] n;

  pack_bits dut (
    .n_m(n_m),
    .n_e(n_e),
    .n_s(n_s),
    .n(n)
  );

  initial begin
	  // Test case 1: Normal positive value
		n_m = 24'h123456;
		n_e = 10'd10;
		n_s = 0;
		#10;
		$display("Test case 1:");
		$display("  Input:  n_m = %h, n_e = %d, n_s = %b", n_m, n_e, n_s);
		$display("  Output: n = %h", n);
		assert(n === 32'h44923456) else $error("Test case 1 failed");

		// Test case 2: Normal negative value
		n_m = 24'h789ABC;
		n_e = 10'd20;
		n_s = 1;
		#10;
		$display("Test case 2:");
		$display("  Input:  n_m = %h, n_e = %d, n_s = %b", n_m, n_e, n_s);
		$display("  Output: n = %h", n);
		assert(n === 32'hC9F89ABC) else $error("Test case 2 failed");

    // Test case 3: Denormalized value
    n_m = 24'h000001;
    n_e = -126;
    n_s = 0;
    #10;
    $display("Test case 3:");
    $display("  Input:  n_m = %h, n_e = %d, n_s = %b", n_m, n_e, n_s);
    $display("  Output: n = %h", n);
    assert(n === 32'h00000001) else $error("Test case 3 failed");

    // Test case 4: Zero value
    n_m = 24'h000000;
    n_e = -126;
    n_s = 0;
    #10;
    $display("Test case 4:");
    $display("  Input:  n_m = %h, n_e = %d, n_s = %b", n_m, n_e, n_s);
    $display("  Output: n = %h", n);
    assert(n === 32'h00000000) else $error("Test case 4 failed");

    // Test case 5: Overflow (+inf)
    n_m = 24'h000000;
    n_e = 128;
    n_s = 0;
    #10;
    $display("Test case 5:");
    $display("  Input:  n_m = %h, n_e = %d, n_s = %b", n_m, n_e, n_s);
    $display("  Output: n = %h", n);
    assert(n === 32'h7F800000) else $error("Test case 5 failed");

    // Test case 6: Overflow (-inf)
    n_m = 24'h000000;
    n_e = 128;
    n_s = 1;
    #10;
    $display("Test case 6:");
    $display("  Input:  n_m = %h, n_e = %d, n_s = %b", n_m, n_e, n_s);
    $display("  Output: n = %h", n);
    assert(n === 32'hFF800000) else $error("Test case 6 failed");

    $finish;
  end

endmodule