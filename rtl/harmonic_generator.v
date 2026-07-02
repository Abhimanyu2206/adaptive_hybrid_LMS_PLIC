`timescale 1ns / 1ps

module harmonic_generator
(
    input  wire signed [7:0] x,

    output wire signed [7:0]  xf60,
    output wire signed [16:0] xf120,
    output wire signed [25:0] xf180,
    output wire signed [35:0] xf240
);

    // Internal Signals

    wire signed [15:0] x2;
    wire signed [23:0] x3;
    wire signed [31:0] x4;

    // Arithmetic Blocks
    radix4_square_8 sq1
    (
        .x(x),
        .x2(x2)
    );

    multiplier_16x8 mul1
    (
        .a(x2),
        .b(x),
        .p(x3)
    );

    radix4_square_16 sq2
    (
        .x(x2),
        .x2(x4)
    );

    //--------------------------------------------------
    // XF60
    //--------------------------------------------------

    assign xf60 = x;

    //--------------------------------------------------
    // XF120 = 2X² - 1
    //--------------------------------------------------

    assign xf120 = (x2 << 1) - 1;

    //--------------------------------------------------
    // 3X
    //--------------------------------------------------

    wire signed [9:0] three_x;

    assign three_x = x + (x << 1);

    //--------------------------------------------------
    // XF180 Compressor
    //--------------------------------------------------

    wire signed [25:0] xf180_comp;

    compressor3_2 #(.WIDTH(26))
    COMP1
    (
        .A( {{2{x3[23]}}, x3} <<< 2 ),
        .B( {{16{three_x[9]}}, three_x} ),
        .C( 26'sd0 ),
        .RESULT( xf180_comp )
    );

    assign xf180 = xf180_comp;

    //--------------------------------------------------
    // XF240 Compressor
    //--------------------------------------------------

    wire signed [35:0] xf240_comp;

    compressor3_2 #(.WIDTH(36))
    COMP2
    (
        .A( {{4{x4[31]}}, x4} <<< 3 ),
        .B( {{10{xf180[25]}}, xf180} ),
        .C( 36'sd3 ),
        .RESULT( xf240_comp )
    );

    assign xf240 = xf240_comp;

endmodule
