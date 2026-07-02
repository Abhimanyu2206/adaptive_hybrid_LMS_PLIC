`timescale 1ns / 1ps

module adaptive_mu_unit
(
    input  wire signed [15:0] error_in,
    output wire [15:0] mu_out
);

    wire signed [15:0] abs_error = (error_in < 0) ? -error_in : error_in;
    
    // Parallel combinational mapping bypasses cascading carry lines
    reg [15:0] mu_reg;
    always @(*) begin
        if (abs_error >= 16'd256)
            mu_reg = 16'd4;
        else if (abs_error >= 16'd128)
            mu_reg = 16'd3;
        else
            mu_reg = 16'd2;
    end
    assign mu_out = mu_reg;

endmodule
