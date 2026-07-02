`timescale 1ns / 1ps

module multiplier_16x8
(
    input  wire [15:0] a,
    input  wire [7:0]  b,

    output wire [23:0] p
);

    assign p = a * b;

endmodule
