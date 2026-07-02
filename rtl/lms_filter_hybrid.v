`timescale 1ns / 1ps

module lms_filter_hybrid
(
    input  wire clk,
    input  wire rst,
    input  wire signed [15:0] x_ref,
    input  wire signed [15:0] error_in,
    output reg  signed [31:0] y_out,
    // DEBUG OUTPUTS
    output wire [1:0] dbg_state,
    output wire signed [15:0] dbg_Re,
    output wire signed [15:0] dbg_mu,
    output wire signed [31:0] dbg_rho,
    output wire signed [15:0] dbg_Rn
);

    //--------------------------------------------------
    // Registers
    //--------------------------------------------------
    reg signed [15:0] Rx;
    reg signed [15:0] R0;
    reg signed [15:0] R1;
    reg signed [15:0] Rn;
    reg signed [15:0] Re;
    reg signed [31:0] mult_reg;
    reg [1:0] state;

    //--------------------------------------------------
    // Adaptive mu & Mode Units
    //--------------------------------------------------
    wire signed [15:0] mu_dynamic;
    adaptive_mu_unit MU_UNIT (
        .error_in(Re),
        .mu_out(mu_dynamic)
    );

    wire mode_select;
    hybrid_mode_controller MODE_CTRL (
        .error_in(Re),
        .mode_select(mode_select)
    );

    wire signed [15:0] sign_update;
    sign_lms_update SIGN_UPDATE (
        .x_ref(Rx),
        .rho(Rn),
        .update_out(sign_update)
    );

    //--------------------------------------------------
    // Mux-Shift Logic (No DSP Primitive used here)
    //--------------------------------------------------
    wire signed [31:0] rho_debug;
    reg signed [31:0] rho_mux;
    always @(*) begin
        case (mu_dynamic)
            16'd2:   rho_mux = $signed(Re) <<< 1;
            16'd3:   rho_mux = ($signed(Re) <<< 1) + $signed(Re);
            16'd4:   rho_mux = $signed(Re) <<< 2;
            default: rho_mux = $signed(Re) <<< 1;
        endcase
    end
    assign rho_debug = rho_mux;

    //--------------------------------------------------
    // Forward Datapath
    //--------------------------------------------------
    wire signed [31:0] mult_a = (x_ref * R1) >>> 9;
    wire signed [31:0] temp_sum = mult_a + R0;

    //--------------------------------------------------
    // Debug Mappings
    //--------------------------------------------------
    assign dbg_state = state;
    assign dbg_Re    = Re;
    assign dbg_mu    = mu_dynamic;
    assign dbg_rho   = rho_debug;
    assign dbg_Rn    = Rn;
    
    //--------------------------------------------------
    function signed [15:0] sat16(input signed [31:0] val);
        begin
            if (val >  32'sd32767) sat16 =  16'sd32767;
            else if (val < -32'sd32768) sat16 = -16'sd32768;
            else sat16 = val[15:0];
        end
    endfunction
    //--------------------------------------------------

    //--------------------------------------------------
    // Sequential Control Logic
    //--------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= 2'd0;
            Rx    <= 16'sd0;
            R0    <= 16'sd0;
            R1    <= 16'sd0;
            Rn    <= 16'sd0;
            Re    <= 16'sd0;
            y_out <= 32'sd0;
        end else begin
            case(state)
                2'd0: begin
                    Rx    <= x_ref;
                    y_out <= temp_sum;
                    Re    <= error_in;
                    state <= 2'd1;
                end
                2'd1: begin
                    Rn    <= rho_debug[23:8]; // Streamlined bit-extraction
                    state <= 2'd2;
                end
                2'd2: begin
                    R0       <= R0 - (R0 >>> 8) + Rn;
                    mult_reg <= (mode_select == 1'b0) ?
                                    ((Rx * Rn) >>> 7) :
                                    (sign_update >>> 4);
                    state    <= 2'd3;
                end
                2'd3: begin
                    R1    <= sat16(R1 + mult_reg);
                    state <= 2'd0;
                end
            endcase
        end
    end
endmodule
