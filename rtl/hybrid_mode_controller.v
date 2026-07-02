`timescale 1ns / 1ps

module hybrid_mode_controller
#(
    parameter THRESHOLD = 16'sd64   // tune using hybrid_lms_error.txt
)
(
    input  wire signed [15:0] error_in,
    output wire mode_select
);

    wire [15:0] abs_error;
    assign abs_error = (error_in < 0) ? -error_in : error_in;
    assign mode_select = (abs_error > THRESHOLD) ? 1'b0 : 1'b1;

endmodule
