module fp_special_cases(
		input	logic 					clk,
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
    localparam [7:0] ZERO_E = 8'h00;
		localparam [7:0] MAX_E = 8'hFF;
    localparam [22:0] ZERO_M = 23'h0;

    logic a_s = a[31];
    logic [7:0] a_e = a[30:23];
    logic [22:0] a_m = a[22:0];

    logic b_s = b[31];
    logic [7:0] b_e = b[30:23];
    logic [22:0] b_m = b[22:0];

		always @(posedge clk) begin
        a_is_zero = (a_e == ZERO_E) && (a_m == ZERO_M);
        b_is_zero = (b_e == ZERO_E) && (b_m == ZERO_M);
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

// module fp_normalize_round(
// 		input        				clk,
//     input        				s,
//     input logic [7:0] 	e,
//     input logic [24:0] 	m,
//     output logic        result
// );
//     logic [7:0] adjusted_e;
//     logic [24:0] adjusted_m;
//     logic ceiling;
//     logic overflow;

//     // Normalize the result
//     always @(posedge clk) begin
//         // Find the position of the leading 1 in the mantissa
//         int leading_one_idx;
//         leading_one_idx = $high(m);

//         // Adjust exponent and mantissa based on the leading 1 position
//         if (leading_one_idx < 23) begin
//             adjusted_e = e - (23 - leading_one_idx);
//             adjusted_m = m << (23 - leading_one_idx);
//         end else begin
//             adjusted_e = e + (leading_one_idx - 23);
//             adjusted_m = m >> (leading_one_idx - 23);
//         end

//         // // Round the result (assuming round-to-nearest, ties-to-even)
//         // logic = adjusted_m[0];  // Least significant bit of the result
//         // logic guard = adjusted_m[1];  // Guard bit (first bit after the LSB)
//         // logic round = adjusted_m[2];  // Round bit (second bit after the LSB)
//         // logic sticky = | adjusted_m[3:2];  // Sticky bit (OR of remaining bits)

//         // ceiling = guard && (round || sticky || lsb);

//         // // Perform rounding
//         // if (ceiling) begin
//         //     adjusted_m = adjusted_m + 2;
//         //     // Handle overflow from rounding
//         //     if (adjusted_m[24]) begin
//         //         adjusted_e = adjusted_e + 1;
//         //         adjusted_m = adjusted_m >> 1;
//         //     end
//         // end

//         // // Handle overflow after rounding
//         // overflow = (adjusted_e >= 8'hFF);

//         // Assemble the final result
//         // Representing infinity with the correct sign
//         if (overflow) begin
//             result = {s, 8'hFF, 23'h0};
//         end
//         // Mask off the implicit bit as it's not stored in IEEE format
//         else begin
//             result = {s, adjusted_e, adjusted_m[23:1]};
//         end
//     end
// endmodule


typedef enum logic [4:0] {
  START           = 4'd0,
  UNPACK_NR       = 4'd1,
  SPECIAL_CASE    = 4'd2,
  NORMALIZE       = 4'd3,
  ROUND           = 4'd4,
  PACK_RESULT     = 4'd5,
  READY           = 4'd6,
  IDLE            = 4'd7,
  UNPACK_NR2      = 4'd8,
  ALIGN      = 4'd9,
  ADD             = 4'd10,
  ROUND2          = 4'd11,
  ADD2          = 4'd12,
  PRECHECK      = 4'd13
} adder_stage_t;


module fp_adder(input logic           clk,
                input logic           reset,
                input logic [31:0]    op1,
                input logic [31:0]    op2,
                input logic           valid,
                output logic [31:0]   result,
                output logic          done
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
  logic [27:0] op1_aligned_m, op2_aligned_m;
  logic [27:0] sum;  // Include carry in the sum
  logic sign_of_result;

  adder_stage_t adder_stage;

  initial begin
    adder_stage = IDLE;
  end

  fp_special_cases special_case_unit(
    .clk(clk),
    .a(op1),
    .b(op2),
    .a_is_zero(op1_is_zero),
    .b_is_zero(op2_is_zero),
    .a_is_inf(op1_is_inf),
    .b_is_inf(op2_is_inf),
    .a_is_nan(op1_is_nan),
    .b_is_nan(op2_is_nan),
    .result(special_result)
	);

  logic a_denorm, b_denorm;
  logic guard, round, sticky;

	always @(posedge clk) begin
    if (reset && adder_stage == IDLE) begin
      adder_stage <= START;
      done <= 0;
      $display("if (reset) begin");
    end else begin
      case (adder_stage)
				START: begin
          $display("START valid=%h", valid);
					if (valid) begin
            $display("START");
            $display("op1: %d, op2: %d", op1, op2);
						a <= op1;
						b <= op2;
            done <= 0;
            a_m <= {op1[22:0], 3'd0};
            b_m <= {op2[22:0], 3'd0};
            // Stored exponents
            a_e <= op1[30:23] - 127;
            b_e <= op2[30:23] - 127;
            a_s <= op1[31];
            b_s <= op2[31];
            // Case 1: exponents == 0000 0000
            a_denorm = (op1[30:23] == 8'h00);
            b_denorm = (op2[30:23] == 8'h00);
						adder_stage <= UNPACK_NR;
					end
				end // START

				UNPACK_NR: begin
          // $display("%h + %h = %h", op1, op2, result);
          $display("%b", op1);
          $display("%b", op2);
          $display("--------------------------------");
          $display("a_m=%d (%b) a_e=%d (%b) a_s=%d (%b)", a_m, a_m, a_e, a_e, a_s, a_s);
          $display("b_m=%d (%b) b_e=%d (%b) b_s=%d (%b)", b_m, b_m, b_e, b_e, b_s, b_s);
          // $display("a_e: %h, b_e: %h", a_e, b_e);
          $display("UNPACK_NR");

          // Assign the exponent values based on denormalized or normalized numbers
          a_e = a_denorm ? 10'h1FF : {2'b00, op1[30:23]} - 127;
          b_e = b_denorm ? 10'h1FF : {2'b00, op2[30:23]} - 127;
          // Determine the larger exponent, smaller exponent, and exponent diff
          larger_e = (a_e >= b_e) ? a_e : b_e;
          smaller_e = (a_e >= b_e) ? b_e : a_e;
          e_delta = larger_e - smaller_e; // For alignment of the binary pt
          adder_stage <= PRECHECK;
        end

        PRECHECK: begin
          if (a_e == 255 || b_e == 255) begin
            adder_stage <= READY;
          end else if (a_e == 0 && a_m == 0 || b_e == 0 && b_m == 0) begin
            if (a_e == 0) begin
              z <= op2;
            end else begin
              z <= op1;
            end
            adder_stage <= READY;
          end
          //Denormalised Number
          if ($signed(a_e) == -127) begin
            $display("SPECIAL_CASE denorm 1");
            a_e <= -126;
          end else begin
            $display("SPECIAL_CASE denorm 2");
            a_m[26] <= 1;
          end

          if ($signed(b_e) == - 127) begin
            $display("SPECIAL_CASE denorm 3");
            b_e <= -126;
          end else begin
            $display("SPECIAL_CASE denorm 4");
            b_m[26] <= 1;
          end
          adder_stage <= ALIGN;
        end

        ALIGN: begin
          $display("a_m=%d (%b) a_e=%d (%b) a_s=%d (%b)", a_m, a_m, a_e, a_e, a_s, a_s);
          $display("b_m=%d (%b) b_e=%d (%b) b_s=%d (%b)", b_m, b_m, b_e, b_e, b_s, b_s);
          $display("larger_e=%d (%b), smaller_e=%d (%b), e_delta=%d (%b)", larger_e, larger_e, smaller_e, smaller_e, e_delta, e_delta);
          // $display("larger_e=%b, smaller_e=%b, e_delta=%b", larger_e, smaller_e, e_delta);
          $display("ALIGN");
          // Align mantissa components based on the exponent diff
          if ($signed(a_e) > $signed(b_e)) begin
            op1_aligned_m <= {1'b1, a_m[26:0]};
            op2_aligned_m <= {1'b1, b_m[26:0]} >> e_delta;
            b_e <= b_e + 1;
            b_m <= b_m >> 1;
            b_m[0] <= b_m[0] | b_m[1];
          end else if ($signed(b_e) > $signed(a_e)) begin
            op1_aligned_m <= {1'b1, a_m[26:0]} >> e_delta;
            op2_aligned_m <= {1'b1, b_m[26:0]};
            a_e <= a_e + 1;
            a_m <= a_m >> 1;
            a_m[0] <= a_m[0] | a_m[1];
          end
          if (op1_is_zero || op2_is_zero || op1_is_inf || op2_is_inf || op1_is_nan || op2_is_nan) begin
            adder_stage <= SPECIAL_CASE;
          end else begin
            adder_stage <= ADD;
          end
    		end // ALIGN

        ADD: begin
          $display("op1_aligned_m=%b, op2_aligned_m=%b", op1_aligned_m, op2_aligned_m);
          $display("ADD");
          z_e <= a_e;
          if (a_s == b_s) begin
            sum <= a_m + b_m;
            // sum <= {1'b0, a_m} + {1'b0, b_m};
            z_s <= a_s;
          end else begin
            if (a_m >= b_m) begin
              sum <= a_m - b_m;
              // sum <= {1'b0, a_m} - {1'b0, b_m};
              z_s <= a_s;
            end else begin
              sum <= {1'b0, b_m} - {1'b0, a_m};
              z_s <= b_s;
            end
          end
          adder_stage <= ADD2;
        end // ADD
        ADD2: begin
          $display("sum=%b, z_s=%b, z_m=%b", sum, z_s, z_m);
          $display("ADD2");
          if (sum[27]) begin
            z_m <= sum[27:4];
            guard <= sum[3];
            round <= sum[2];
            sticky <= sum[1] | sum[0];
            z_e <= z_e + 1;
          end else begin
            z_m <= sum[26:3];
            guard <= sum[2];
            round <= sum[1];
            sticky <= sum[0];
          end
          adder_stage <= NORMALIZE;
        end // ADD2

        NORMALIZE: begin
          $display("sum=%b, z_s=%b, z_m=%b", sum, z_s, z_m);
          $display("op1_aligned_m=%b, op2_aligned_m=%b", op1_aligned_m, op2_aligned_m);
          $display("%b + %b = %b", op1, op2, sum);
          $display("NORMALIZE");
          // OVERFLOW: SR the hidden bit
          if (sum[24]) begin
            $display("NORMALIZE: sum[24] - OVERFLOW");
            // z_m <= sum[24:1];
            z_e <= larger_e + 1;
          end else begin
            // NO OVERFLOW
            if (sum[23]) begin
              $display("NORMALIZE: sum[23]");
              z_m <= sum[22:0];
              z_e <= larger_e;
            end else if (sum[22]) begin
              $display("NORMALIZE: sum[22]");
              z_m <= {sum[21:0], 1'b0};
              z_e <= larger_e - 1;
            end else if (sum[21]) begin
              $display("NORMALIZE: sum[21]");
              z_m <= {sum[20:0], 2'b00};
              z_e <= larger_e - 2;
            end else if (sum[20]) begin
              $display("NORMALIZE: sum[20]");
              z_m <= {sum[19:0], 3'b000};
              z_e <= larger_e - 3;
            end else begin
              $display("NORMALIZE: else case (underflow)");
              // Underflow occurred: set result to zero
              z_m <= 24'b0;
              z_e <= 10'b0;
            end
          end
          adder_stage <= ROUND;
        end

        ROUND: begin
          $display("sum=%b, z_s=%b, z_m=%b", sum, z_s, z_m);
          $display("guard=%b round=%b sticky=%b", guard, round, sticky);
          $display("z_m=%b z_e=%b z_s=%b", z_m, z_e, z_s);
          $display("sum=%b", sum);
          $display("");
          $display("ROUND");
          // Extract the guard, round, and sticky bits
          guard = z_m[1];
          round = z_m[2];
          sticky = |z_m[24:3];
          adder_stage <= ROUND2;
        end
        ROUND2: begin
          $display("sum=%b, z_s=%b, z_m=%b", sum, z_s, z_m);
          $display("guard=%h round=%h sticky=%h", guard, round, sticky);
          $display("\nROUND2");
          // Perform rounding based on the guard, round, and sticky bits
          if (guard && (round | sticky | z_m[0])) begin
            z_m <= z_m + 1;
            if (z_m == 24'hffffff) begin
              // Rounding caused overflow: shift right and increment exponent
              // z_m <= z_m[24:1];
              z_e <= z_e + 1;
            end
          end else begin
            // No rounding needed, just truncate the mantissa
            $display("no rounding needed");
            // z_m <= z_m[24:1];
          end
          adder_stage <= SPECIAL_CASE;
        end
        SPECIAL_CASE: begin
          $display("guard=%b round=%b sticky=%b", guard, round, sticky);
          $display("z_m=%b z_e=%b z_s=%b", z_m, z_e, z_s);
          $display("sum=%b", sum);
          $display("SPECIAL_CASE");
          z[22:0] <= z_m[22:0];
          z[30:23] <= z_e[7:0] + 127;
          z[31] <= z_s;
          if ($signed(z_e) == -126 && z_m[23] == 0) begin
            z[30:23] <= 0;
          end
          if ($signed(z_e) == -126 && z_m[23:0] == 24'h0) begin
            z[31] <= 1'b0; // FIX SIGN BUG: -a + a = +0.
          end
          //if overflow occurs, return inf
          if ($signed(z_e) > 127) begin
            z[22:0] <= 0;
            z[30:23] <= 255;
            z[31] <= z_s;
          end
          adder_stage <= READY;
        end
        READY: begin
          $display("guard=%b round=%b sticky=%b", guard, round, sticky);
          $display("z_m=%b z_e=%b z_s=%b", z_m, z_e, z_s);
          $display("sum=%b", sum);
          $display("");
          $display("READY: result <= %h", z);
          done        <= 1;
          result     <= z;
          adder_stage      <= IDLE;
        end
      endcase
    end
  end
endmodule
