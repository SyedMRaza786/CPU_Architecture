module fp_special_cases(
		input	logic 					clk
    input [31:0] 					a,
    input [31:0] 					b,
    output logic 					a_is_zero,
    output logic  				b_is_zero,
    output logic  				a_is_inf,
    output logic 					b_is_inf,
    output logic 					a_is_nan,
    output logic 					b_is_nan,
    output logic [31:0] 	result
);

		localparam [7:0] MAX_E = 8'hFF;
    localparam [22:0] ZERO_M = 23'h0;

    logic a_s = a[31];
    logic [7:0] a_e = a[30:23];
    logic [22:0] a_m = a[22:0];

    logic b_s = b[31];
    logic [7:0] b_e = b[30:23];
    logic [22:0] b_m = b[22:0];

		always @(negedge reset or posedge clk) begin
        a_is_zero = (a_e == 8'h00) && (a_m == ZERO_M);
        b_is_zero = (b_e == 8'h00) && (b_m == ZERO_M);
        a_is_inf = (a_e == MAX_E) && (a_m == ZERO_M);
        b_is_inf = (b_e == MAX_E) && (b_m == ZERO_M);
        a_is_nan = (a_e == MAX_E) && (a_m != ZERO_M);
        b_is_nan = (b_e == MAX_E) && (b_m != ZERO_M);

				// Quiet NaN (qNaN) representation
        if (a_is_nan || b_is_nan) begin result = {1'b0, MAX_E, 23'h400000}; end
				// Quiet NaN (qNaN) for inf - inf
				else if (a_is_inf && b_is_inf && (a_s != b_s)) begin result = {1'b0, MAX_E, 23'h400000}; end
				// Correctly signed inf
				else if (a_is_inf || b_is_inf) begin result = {a_s | b_s, MAX_E, ZERO_M}; end
				// Correctly signed zero
				else if (a_is_zero && b_is_zero) begin result = {a_s & b_s, 31'h0}; end
				// NaN and inf NOT detected!
				else begin result = 32'h0; end
    end
endmodule

module fp_normalize_round(
		input logic 				clk,
    input logic 				s,
    input logic [7:0] 	e,
    input logic [24:0] 	m,
    output logic [31:0] result
);
    logic [7:0] adjusted_e;
    logic [24:0] adjusted_m;
    logic ceiling;
    logic overflow;

    // Normalize the result
    always @(negedge reset or posedge clk) begin
        // Find the position of the leading 1 in the mantissa
        int leading_one_idx;
        leading_one_idx = $high(m);

        // Adjust exponent and mantissa based on the leading 1 position
        if (leading_one_idx < 23) begin
            adjusted_e = e - (23 - leading_one_idx);
            adjusted_m = m << (23 - leading_one_idx);
        end else begin
            adjusted_e = e + (leading_one_idx - 23);
            adjusted_m = m >> (leading_one_idx - 23);
        end

        // Round the result (assuming round-to-nearest, ties-to-even)
        logic lsb = adjusted_m[0];  // Least significant bit of the result
        logic guard = adjusted_m[1];  // Guard bit (first bit after the LSB)
        logic round = adjusted_m[2];  // Round bit (second bit after the LSB)
        logic sticky = | adjusted_m[3:2];  // Sticky bit (OR of remaining bits)

        ceiling = guard && (round || sticky || lsb);

        // Perform rounding
        if (ceiling) begin
            adjusted_m = adjusted_m + 2;
            // Handle overflow from rounding
            if (adjusted_m[24]) begin
                adjusted_e = adjusted_e + 1;
                adjusted_m = adjusted_m >> 1;
            end
        end

        // Handle overflow after rounding
        overflow = (adjusted_e >= 8'hFF);

        // Assemble the final result
        // Representing infinity with the correct sign
        if (overflow) begin
            result = {s, 8'hFF, 23'h0};
        end
        // Mask off the implicit bit as it's not stored in IEEE format
        else begin
            result = {s, adjusted_e, adjusted_m[23:1]};
        end
    end
endmodule


///////////////////////////////////////////////////
//																							//
// unpacks 2 floating-point values => bits			//
//																							//
///////////////////////////////////////////////////
module unpack_bits (
  input        [31:0] a,
  input        [31:0] b,
  output logic [26:0] a_m, // 27-bit mantissa
  output logic [26:0] b_m,
  output logic [9:0]  a_e, // 10-bit exponent
  output logic [9:0]  b_e,
  output logic        a_s, // sign bit
  output logic        b_s
);

  assign a_m = {a[22:0], 3'd0};
  assign b_m = {b[22:0], 3'd0};
  assign a_e = a[30:23] - 127;
  assign b_e = b[30:23] - 127;
  assign a_s = a[31];
  assign b_s = b[31];

endmodule


///////////////////////////////////////////////////
//																							//
// packs bits => floating-point value				   	//
//																							//
///////////////////////////////////////////////////
module pack_bits (
  input        [23:0] m,
  input        [9:0]  e,
  input logic        	s,
  output logic [31:0] n
);

  always_comb begin
    n = {s, e[7:0] + 8'd127, m[22:0]};

    if ($signed(e) == -126) begin
      if (m[23] == 0) begin
        n[30:23] = 0;
      end
      if (m == 24'h0) begin
        n[31] = 1'b0;
      end
    end

		// Overflow case
    if ($signed(e) > 127) begin n = {s, 8'hFF, 23'h0}; end
  end
endmodule


typedef enum logic [3:0] {
  START           = 4'd0,
	UNPACK_NR 			= 4'd1,
  SPECIAL_CASE    = 4'd2,
  NORMALIZE_ROUND = 4'd3,
	PACK_RESULT			= 4'd4,
  READY           = 4'd5
} adder_stage_t;


module fp_adder(
		input logic          	clk,
		input logic 					reset,
    input logic [31:0]		op1,
    input logic [31:0]		op2,
		input logic 					valid,
    output logic [31:0]		result,
		output logic 					done
);

	logic       [31:0] a, b, z;
  logic       [26:0] a_m, b_m;
  logic       [23:0] z_m;
  logic       [9:0] a_e, b_e, z_e;
  logic       a_s, b_s, z_s;

	logic op1_is_zero, op2_is_zero, op1_is_inf, op2_is_inf, op1_is_nan, op2_is_nan;
	logic [31:0] special_result;
	logic op1_s = op1[31];
	logic [7:0] op1_e = op1[30:23];
	logic [22:0] op1_m = {1'b1, op1[22:0]};  // Assumes normalized
	logic sign_op2 = op2[31];
	logic [7:0] op2_e = op2[30:23];
	logic [22:0] op2_m = {1'b1, op2[22:0]};  // Assumes normalized
	logic [7:0] larger_e, smaller_e, e_delta;
	logic [23:0] op1_aligned_m, op2_aligned_m;
	logic [24:0] sum;  // Include carry in the sum
	logic sign_result;

	adder_stage_t adder_stage;

	unpack_bits unpacked(
			.a(op1),
			.b(op2),
			.a_m(a_m),
			.b_m(b_m),
			.a_e(a_e),
			.b_e(b_e),
			.a_s(a_s),
			.b_s(b_s)
	);

	fp_special_cases special_case_unit(
			.op1(op1),
			.op2(op2),
			.op1_is_zero(op1_is_zero),
			.op2_is_zero(op2_is_zero),
			.op1_is_inf(op1_is_inf),
			.op2_is_inf(op2_is_inf),
			.op1_is_nan(op1_is_nan),
			.op2_is_nan(op2_is_nan),
			.result(special_result)
	);

	// Determine the larger exponent and the exponent difference
	always @(negedge reset or posedge clk) begin
		if (reset == 0) begin
			state <= START;
			done <= 0;
		end else begin
			case(adder_stage)
				START: begin
					if (valid) begin
						a <= op1;
						b <= op2;
						state <= UNPACK_NR;
					end
				end
				UNPACK_NR: begin
					a_m <= unpacked.a_m;
					b_m <= unpacked.b_m;
					a_e <= unpacked.a_e;
					b_e <= unpacked.b_e;
					a_s <= unpacked.a_s;
					b_s <= unpacked.b_s;
				end


    larger_e = (a_e >= b_e) ? a_e : b_e;
    smaller_e = (a_e >= b_e) ? b_e : a_e;
    e_delta = larger_e - smaller_e;

		/// MANTISSA COMPUTATION
		// Align mantissa components
    op1_aligned_m = (a_e >= b_e) ? {1'b0, a_m} : ({1'b0, a_m} >> e_delta);
    op2_aligned_m = (a_e < b_e) ? {1'b0, b_m} : ({1'b0, b_m} >> e_delta);

    if (a_s == b_s) begin
        sum = {1'b0, op1_aligned_m} + {1'b0, op2_aligned_m}; // Prevent carry-out
        sign_result = a_s;
		end else begin
        // Ensure magnitude comparison is based on original, unshifted significands
        if (a_e > b_e || (a_e == b_e && a_m >= b_m)) begin
            sum = {1'b0, op1_aligned_m} - {1'b0, op2_aligned_m};
            sign_result = a_s;
				end else begin
            sum = {1'b0, op2_aligned_m} - {1'b0, op1_aligned_m};
            sign_result = b_s;
				end
		end
    // Adjust exponent for alignment
    larger_e += sum[24]; // Adjust exponent if there was an overflow
    sum = sum[24] ? sum >> 1 : sum; // Right shift sum if there was an overflow
	
	PACK_RESULT: begin
  result <= pack_bits(z_m, z_e, z_s);
  adder_stage <= READY;
end

	READY: begin
  done <= 1;
  if (!valid) begin
    adder_stage <= START;
    done <= 0;
  end
end
	
fp_normalize_round normalize_round_unit(
        .sign(sign_result),
        .e(larger_e),
        .mantissa(sum),
        .result(normalized_result)
    );

    // Select the final result based on special cases
    always_comb begin
        if (special_result != 32'h0) begin
            result = special_result;
        end else begin
            result = normalized_result;
        end
    end
endmodule