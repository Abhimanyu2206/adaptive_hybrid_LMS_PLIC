`timescale 1ns / 1ps

module sign_lms_update
(
    input  wire signed [15:0] x_ref,
    input  wire signed [15:0] rho,

    output wire signed [15:0] update_out
);

    assign update_out =
        (x_ref >= 0) ? rho : -rho;

endmodule
