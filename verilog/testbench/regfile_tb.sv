`timescale 1ns/1ps
`include "sys_defs.svh"

module regfile_tb;

logic clock;
logic [4:0] readA_idx_1, readB_idx_1, readA_idx_2, readB_idx_2;
logic [4:0] write_idx_1, write_idx_2;
logic write_en_1, write_en_2;
logic [`XLEN-1:0] write_data_1, write_data_2;
logic [`XLEN-1:0] readA_out_1, readB_out_1, readA_out_2, readB_out_2;

int passed = 0;
int failed = 0;
logic test_failed = 1'b0;

regfile dut (
    .clock(clock),
    .readA_idx_1(readA_idx_1),
    .readB_idx_1(readB_idx_1),
    .readA_idx_2(readA_idx_2),
    .readB_idx_2(readB_idx_2),
    .write_idx_1(write_idx_1),
    .write_idx_2(write_idx_2),
    .write_en_1(write_en_1),
    .write_en_2(write_en_2),
    .write_data_1(write_data_1),
    .write_data_2(write_data_2),
    .readA_out_1(readA_out_1),
    .readB_out_1(readB_out_1),
    .readA_out_2(readA_out_2),
    .readB_out_2(readB_out_2)
);

always begin
    clock = 0;
    forever #5 clock = ~clock;
end

initial begin
    readA_idx_1 = 0;
    readB_idx_1 = 0;
    readA_idx_2 = 0;
    readB_idx_2 = 0;
    write_idx_1 = 0;
    write_idx_2 = 0;
    write_en_1 = 0;
    write_en_2 = 0;
    write_data_1 = 0;
    write_data_2 = 0;
    test_failed = 1'b0;

	  $display("\Begin test cases for regfile\n====================================");

    // Test case 1: Write to registers and read back
    #10;
    write_en_1 = 1;
    write_idx_1 = 5;
    write_data_1 = 32'hDEADBEEF;
    #10;
    write_idx_1 = 10;
    write_data_1 = 32'hCAFEBABE;
    #10;
    write_en_1 = 0;
    readA_idx_1 = 5;
    readB_idx_1 = 10;
    #10;
    if (readA_out_1 !== 32'hDEADBEEF || readB_out_1 !== 32'hCAFEBABE) begin
        $display("Test case 1:");
        $display("  Register 5 contains: %h", readA_out_1);
        $display("  Register 10 contains: %h", readB_out_1);
        $error("Test case 1 failed for writing to 2 regs, followed by read back");
        test_failed = 1'b1;
    end else begin $display("Test case 1: write to 2 registers, followed by read back ... PASSED"); end
    if (test_failed) begin failed = failed + 1; end
    else begin passed = passed + 1; end

  	test_failed = 1'b0;

    // Test case 2: Write to zero register and read back
    #10;
    write_en_1 = 1;
    write_idx_1 = 0;
    write_data_1 = 32'hFFFFFFFF;
    #10;
    write_en_1 = 0;
    readA_idx_1 = 0;
    #10;
    if (readA_out_1 !== 0) begin
        $display("Test case 2:");
        $display("  Register 0 contains: %h", readA_out_1);
        $error("Test case 2 failed for write/read to zero reg");
        test_failed = 1'b1;
    end else begin $display("Test case 2: write to zero reg and read back ... PASSED"); end
    if (test_failed) begin failed = failed + 1; end
    else begin passed = passed + 1; end

    test_failed = 1'b0;

    // Test case 3: Internal forwarding (write and read in the same cycle)
    #10;
    write_en_1 = 1;
    write_idx_1 = 15;
    write_data_1 = 32'hAAAAAAAA;
    readA_idx_1 = 15;
    #10;
    if (readA_out_1 !== 32'hAAAAAAAA) begin
        $display("Test case 3:");
        $display("  Register 15 contains: %h", readA_out_1);
        $error("Test case 3 failed for internal forwarding");
        test_failed = 1'b1;
    end else begin $display("Test case 3: internal forwarding ... PASSED"); end
    if (test_failed) begin failed = failed + 1; end
    else begin passed = passed + 1; end

    test_failed = 1'b0;

    // Test case 4: Multiple read ports
    #10;
    write_en_1 = 0;
    readA_idx_1 = 5;
    readB_idx_1 = 10;
    readA_idx_2 = 15;
    readB_idx_2 = 0;
    #10;
    if (readA_out_1 !== 32'hDEADBEEF || readB_out_1 !== 32'hCAFEBABE || readA_out_2 !== 32'hAAAAAAAA || readB_out_2 !== 0) begin
        $display("Test case 4:");
        $display("  Register 5 contains: %h", readA_out_1);
        $display("  Register 10 contains: %h", readB_out_1);
        $display("  Register 15 contains: %h", readA_out_2);
        $display("  Register 0 contains: %h", readB_out_2);
        $error("Test case 4 failed for reading from all 4 read ports");
        test_failed = 1'b1;
    end else begin $display("Test case 4: read from all 4 ports ... PASSED"); end
    if (test_failed) begin failed = failed + 1; end
    else begin passed = passed + 1; end

  	test_failed = 1'b0;

  	// Test case 5: Write to the same register from both write ports
    #10;
    write_en_1 = 1;
    write_en_2 = 1;
    write_idx_1 = 20;
    write_idx_2 = 20;
    write_data_1 = 32'h11111111;
    write_data_2 = 32'h22222222;
    #10;
    write_en_1 = 0;
    write_en_2 = 0;
    readA_idx_1 = 20;
    #10;
    if (readA_out_1 !== 32'h22222222) begin
        $display("Test case 5:");
        $display("  Register 20 contains: %h", readA_out_1);
        $error("Test case 5 failed for writing to the same register from both write ports");
        test_failed = 1'b1;
    end else begin $display("Test case 5: write to the same register from both write ports ... PASSED"); end
    if (test_failed) begin failed = failed + 1; end
    else begin passed = passed + 1; end

    test_failed = 1'b0;

	  // Test case 6: Read from an unwritten register
  	for (int i = 1; i < 32; i++) begin
        write_en_1 = 1;
        write_idx_1 = i;
        write_data_1 = 0;
        #10;
    end

    #10;
    readA_idx_1 = 25;
    #10;
    if (readA_out_1 !== 0) begin
        $display("Test case 6:");
        $display("  Register 25 contains: %h", readA_out_1);
        $error("Test case 6 failed for reading from an unwritten register");
        test_failed = 1'b1;
    end else begin $display("Test case 6: read from an unwritten register ... PASSED"); end
    if (test_failed) begin failed = failed + 1; end
    else begin passed = passed + 1; end

    #100;
    $display("====================================\nTest Summary: Passed = %d, Failed = %d\n", passed, failed);
    $finish;
end

endmodule