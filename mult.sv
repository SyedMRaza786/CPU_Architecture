`ifndef __MULT_SV__
`define __MULT_SV__

`timescale 1ns/100ps

module mult (
    input clock, reset,
    input start,
    input [1:0] mode,
    input [`XLEN-1:0] mcand, mplier,
    output [`DW_SIZE-1:0] product,
    output done
);
    logic [`DW_SIZE-1:0] products_stage[3:0], internal_mpliers[3:0], internal_mcands[3:0];
    logic [3:0] done_stage;
    logic [`DW_SIZE-1:0] mcand_in, mplier_in;
    logic sign_mcand, sign_mplier;

    always_comb begin
        case (mode)
            2'b00: {sign_mcand, sign_mplier} = 2'b00; // Unsigned multiplication
            2'b01: {sign_mcand, sign_mplier} = 2'b11; // Signed multiplication
            2'b10: {sign_mcand, sign_mplier} = 2'b00; // Unsigned high multiplication
            2'b11: {sign_mcand, sign_mplier} = 2'b10; // Signed * Unsigned high multiplication
        endcase
    end

    assign mcand_in = sign_mcand ? {{32{mcand[`XLEN-1]}}, mcand} : {32'b0, mcand};
    assign mplier_in = sign_mplier ? {{32{mplier[`XLEN-1]}}, mplier} : {32'b0, mplier};

    mult_stage stage0(
        .clock(clock),
        .reset(reset),
        .start(start),
        .mplier_in(mplier_in),
        .mcand_in(mcand_in),
        .product_in(64'b0),
        .done(done_stage[0]),
        .mplier_out(internal_mpliers[0]),
        .mcand_out(internal_mcands[0]),
        .product_out(products_stage[0])
    );

    mult_stage stage1(
        .clock(clock),
        .reset(reset),
        .start(done_stage[0]),
        .mplier_in(internal_mpliers[0]),
        .mcand_in(internal_mcands[0]),
        .product_in(products_stage[0]),
        .done(done_stage[1]),
        .mplier_out(internal_mpliers[1]),
        .mcand_out(internal_mcands[1]),
        .product_out(products_stage[1])
    );

    mult_stage stage2(
        .clock(clock),
        .reset(reset),
        .start(done_stage[1]),
        .mplier_in(internal_mpliers[1]),
        .mcand_in(internal_mcands[1]),
        .product_in(products_stage[1]),
        .done(done_stage[2]),
        .mplier_out(internal_mpliers[2]),
        .mcand_out(internal_mcands[2]),
        .product_out(products_stage[2])
    );

    mult_stage stage3(
        .clock(clock),
        .reset(reset),
        .start(done_stage[2]),
        .mplier_in(internal_mpliers[2]),
        .mcand_in(internal_mcands[2]),
        .product_in(products_stage[2]),
        .done(done_stage[3]),
        .mplier_out(internal_mpliers[3]),
        .mcand_out(internal_mcands[3]),
        .product_out(products_stage[3])
    );

    assign product = products_stage[`MULT_STAGES - 1];
  	assign done = done_stage[`MULT_STAGES - 1];

endmodule

module mult_stage (
    input clock, reset, start,
    input [`DW_SIZE-1:0] mplier_in, mcand_in,
    input [`DW_SIZE-1:0] product_in,
    input sign_mcand, sign_mplier,

    output logic done,
    output logic [`DW_SIZE-1:0] mplier_out, mcand_out,
    output logic [`DW_SIZE-1:0] product_out
);
    logic [`DW_SIZE-1:0] prod_in_reg, partial_prod, next_partial_product;
    logic [`DW_SIZE-1:0] next_mplier, next_mcand;

    assign product_out = prod_in_reg + partial_prod;
    assign next_partial_product = mplier_in[`BITS_PER_STAGE-1:0] * mcand_in;
    assign next_mplier = {16'b0, mplier_in[`DW_SIZE-1:`BITS_PER_STAGE]};
    assign next_mcand = {mcand_in[47:0], 16'b0};

    always_ff @(posedge clock) begin
        if (reset) begin
            done <= 1'b0;
            prod_in_reg <= 0;
            partial_prod <= 0;
            mplier_out <= 0;
            mcand_out <= 0;
        end else begin
            done <= start;
            prod_in_reg <= product_in;
            partial_prod <= next_partial_product;
            mplier_out <= next_mplier;
            mcand_out <= next_mcand;
        end
    end

endmodule // mult_stage
`endif // __MULT_SV__
