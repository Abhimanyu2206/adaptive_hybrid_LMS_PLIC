`timescale 1ns / 1ps

module radix4_square_16
(
    input  wire signed [15:0] x,
    output wire signed [31:0] x2
);

    wire [15:0] x_abs;

    assign x_abs = (x < 0) ? -x : x;

    wire [7:0] low;
    wire [7:0] high;

    assign low  = x_abs[7:0];
    assign high = x_abs[15:8];

    wire [15:0] low_sq;
    wire [15:0] high_sq;

    wire [16:0] cross;

    assign low_sq  = low  * low;
    assign high_sq = high * high;

    assign cross   = low * high;

    assign x2 =
            low_sq
          + (cross << 9)
          + (high_sq << 16);

endmodule
