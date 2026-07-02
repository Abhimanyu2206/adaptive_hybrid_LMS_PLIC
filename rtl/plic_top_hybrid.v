`timescale 1ns / 1ps

module plic_top_hybrid
(
    input wire clk,
    input wire rst,
    input wire signed [7:0] x_in,
    input wire signed [15:0] d_in,
    output reg signed [15:0] d_out_fpga,     // 16-bit clean bio-signal for physical hardware interface
    output reg               logic_preserve_pin // 1-bit pin to prevent synthesis optimization trimming
);

    // Internal Conversions for Wide Diagnostic Buses
    wire signed [31:0] y_out;
    wire signed [33:0] e_out;
    wire signed [31:0] dbg_y60;
    wire signed [31:0] dbg_y120;
    wire signed [31:0] dbg_y180;
    wire signed [31:0] dbg_y240;

    // Harmonic Generator Outputs
    wire signed [7:0]  xf60;
    wire signed [16:0] xf120;
    wire signed [25:0] xf180;
    wire signed [35:0] xf240;

    // Harmonic Generator (ASIC-Optimized Operators)
    harmonic_generator HG
    (
        .x(x_in),
        .xf60(xf60),
        .xf120(xf120),
        .xf180(xf180),
        .xf240(xf240)
    );

    // Pipelined Harmonic References (Breaks the Critical Path)
    reg signed [15:0] xf60_s;
    reg signed [15:0] xf120_s;
    reg signed [15:0] xf180_s;
    reg signed [15:0] xf240_s;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            xf60_s  <= 16'sd0;
            xf120_s <= 16'sd0;
            xf180_s <= 16'sd0;
            xf240_s <= 16'sd0;
        end else begin
            xf60_s  <= {{8{xf60[7]}}, xf60};
            xf120_s <= xf120 >>> 8;
            xf180_s <= xf180 >>> 16;
            xf240_s <= xf240 >>> 24;
        end
    end

    // Multi-Channel Adaptive Filtering Outputs
    wire signed [31:0] y60;
    wire signed [31:0] y120;
    wire signed [31:0] y180;
    wire signed [31:0] y240;

    // Sub-Module Debugging Probes
    wire [1:0] dbg_state;
    wire signed [15:0] dbg_Re;
    wire signed [15:0] dbg_mu;
    wire signed [31:0] dbg_rho;
    wire signed [15:0] dbg_Rn;

    // Error Decoupling and Saturation Grid
    wire signed [33:0] error_signal;
    wire signed [15:0] error_sat;
    
    assign error_sat = (error_signal > 34'sd32767)  ? 16'sd32767  :
                       (error_signal < -34'sd32768) ? -16'sd32768 :
                                                      error_signal[15:0];

    // Channel Instantiations (LMS60 to LMS240)
    lms_filter_hybrid LMS60
    (
        .clk(clk),
        .rst(rst),
        .x_ref(xf60_s),
        .error_in(error_sat),
        .y_out(y60),
        .dbg_state(dbg_state),
        .dbg_Re(dbg_Re),
        .dbg_mu(dbg_mu),
        .dbg_rho(dbg_rho),
        .dbg_Rn(dbg_Rn)
    );

    lms_filter_hybrid LMS120
    (
        .clk(clk),
        .rst(rst),
        .x_ref(xf120_s),
        .error_in(error_sat),
        .y_out(y120)
    );

    lms_filter_hybrid LMS180
    (
        .clk(clk),
        .rst(rst),
        .x_ref(xf180_s),
        .error_in(error_sat),
        .y_out(y180)
    );

    lms_filter_hybrid LMS240
    (
        .clk(clk),
        .rst(rst),
        .x_ref(xf240_s),
        .error_in(error_sat),
        .y_out(y240)
    );

    // High-Precision Combinational Aggregations
    assign y_out = y60 + y120 + y180 + y240;

    assign dbg_y60  = y60;
    assign dbg_y120 = y120;
    assign dbg_y180 = y180;
    assign dbg_y240 = y240;

    assign error_signal = $signed(d_in) - $signed(y_out);
    assign e_out        = error_signal;

    // Physical Board Interfacing & Logic Preservation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            d_out_fpga         <= 16'sd0;
            logic_preserve_pin <= 1'b0;
        end else begin
            // Route the clean 16-bit bio-signal directly out to a physical pin group
            d_out_fpga         <= error_signal[15:0]; 
            
            // XOR reduction tree forces Vivado to keep the entire logic hierarchy alive
            logic_preserve_pin <= ^y_out ^ ^error_signal ^ ^dbg_y240; 
        end
    end

endmodule
