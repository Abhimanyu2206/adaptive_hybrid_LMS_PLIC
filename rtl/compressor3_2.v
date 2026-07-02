`timescale 1ns / 1ps

module compressor3_2 #
(
    parameter WIDTH = 16
)
(
    input wire signed [WIDTH-1:0] A,
    input wire signed [WIDTH-1:0] B,
    input wire signed [WIDTH-1:0] C,
    output wire signed [WIDTH-1:0] RESULT
);
    assign RESULT = A - B - C;
endmodule
