`timescale 1ns / 1ps

module tb_plic_top_hybrid;
    reg clk;
    reg rst;
    reg signed [7:0]  x_in;
    reg signed [15:0] d_in;
    
    // Captured FPGA Board Connections
    wire signed [15:0] d_out_fpga;
    wire               logic_preserve_pin;
    
    // Internal Reconstructed Signal Trace for Log Compatibility
    wire signed [33:0] e_out;
    assign e_out = $signed(d_out_fpga);

    wire [33:0] abs_e;
    assign abs_e = (e_out < 0) ? -e_out : e_out;

    // Instantiate Bounded-Pin Device Under Test (DUT)
    plic_top_hybrid DUT
    (
        .clk(clk), 
        .rst(rst),
        .x_in(x_in), 
        .d_in(d_in),
        .d_out_fpga(d_out_fpga),
        .logic_preserve_pin(logic_preserve_pin)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer idx;        // 60 Hz noise index (0..63)
    integer becg;       // ECG beat index   (0..99)
    integer fp;
    wire signed [15:0] clean_ecg;

    //--------------------------------------------------
    // 64-point sine LUT (60 Hz reference / noise source)
    //--------------------------------------------------
    reg [7:0] sine_lut [0:63];
    
    //--------------------------------------------------
    // 100-point synthetic ECG beat (the clean bio-signal)
    //--------------------------------------------------
    reg signed [15:0] ecg_lut [0:99];
    assign clean_ecg = ecg_lut[becg];

    initial
    begin
        sine_lut[0]=8'd128;  sine_lut[1]=8'd140;  sine_lut[2]=8'd153;  sine_lut[3]=8'd165;
        sine_lut[4]=8'd176;  sine_lut[5]=8'd188;  sine_lut[6]=8'd198;  sine_lut[7]=8'd208;
        sine_lut[8]=8'd218;  sine_lut[9]=8'd226;  sine_lut[10]=8'd234; sine_lut[11]=8'd240;
        sine_lut[12]=8'd245; sine_lut[13]=8'd250; sine_lut[14]=8'd253; sine_lut[15]=8'd255;
        sine_lut[16]=8'd255; sine_lut[17]=8'd255; sine_lut[18]=8'd253; sine_lut[19]=8'd250;
        sine_lut[20]=8'd245; sine_lut[21]=8'd240; sine_lut[22]=8'd234; sine_lut[23]=8'd226;
        sine_lut[24]=8'd218; sine_lut[25]=8'd208; sine_lut[26]=8'd198; sine_lut[27]=8'd188;
        sine_lut[28]=8'd176; sine_lut[29]=8'd165; sine_lut[30]=8'd153; sine_lut[31]=8'd140;
        sine_lut[32]=8'd128; sine_lut[33]=8'd115; sine_lut[34]=8'd102; sine_lut[35]=8'd90;
        sine_lut[36]=8'd79;  sine_lut[37]=8'd67;  sine_lut[38]=8'd57;  sine_lut[39]=8'd47;
        sine_lut[40]=8'd37;  sine_lut[41]=8'd29;  sine_lut[42]=8'd21;  sine_lut[43]=8'd15;
        sine_lut[44]=8'd10;  sine_lut[45]=8'd5;   sine_lut[46]=8'd2;   sine_lut[47]=8'd0;
        sine_lut[48]=8'd0;   sine_lut[49]=8'd0;   sine_lut[50]=8'd2;   sine_lut[51]=8'd5;
        sine_lut[52]=8'd10;  sine_lut[53]=8'd15;  sine_lut[54]=8'd21;  sine_lut[55]=8'd29;
        sine_lut[56]=8'd37;  sine_lut[57]=8'd47;  sine_lut[58]=8'd57;  sine_lut[59]=8'd67;
        sine_lut[60]=8'd79;  sine_lut[61]=8'd90;  sine_lut[62]=8'd102; sine_lut[63]=8'd115;

        ecg_lut[ 0] = 16'sd0;   ecg_lut[ 1] = 16'sd0;   ecg_lut[ 2] = 16'sd0;   ecg_lut[ 3] = 16'sd0;
        ecg_lut[ 4] = 16'sd1;   ecg_lut[ 5] = 16'sd1;   ecg_lut[ 6] = 16'sd2;   ecg_lut[ 7] = 16'sd4;
        ecg_lut[ 8] = 16'sd5;   ecg_lut[ 9] = 16'sd8;   ecg_lut[10] = 16'sd11;  ecg_lut[11] = 16'sd15;
        ecg_lut[12] = 16'sd19;  ecg_lut[13] = 16'sd24;  ecg_lut[14] = 16'sd29;  ecg_lut[15] = 16'sd33;
        ecg_lut[16] = 16'sd37;  ecg_lut[17] = 16'sd39;  ecg_lut[18] = 16'sd40;  ecg_lut[19] = 16'sd39;
        ecg_lut[20] = 16'sd37;  ecg_lut[21] = 16'sd33;  ecg_lut[22] = 16'sd29;  ecg_lut[23] = 16'sd24;
        ecg_lut[24] = 16'sd19;  ecg_lut[25] = 16'sd15;  ecg_lut[26] = 16'sd11;  ecg_lut[27] = 16'sd8;
        ecg_lut[28] = 16'sd5;   ecg_lut[29] = 16'sd4;   ecg_lut[30] = 16'sd2;   ecg_lut[31] = 16'sd1;
        ecg_lut[32] = 16'sd1;   ecg_lut[33] = 16'sd0;   ecg_lut[34] = 16'sd0;   ecg_lut[35] = 16'sd0;
        ecg_lut[36] = 16'sd0;   ecg_lut[37] = 16'sd0;   ecg_lut[38] = 16'sd0;   ecg_lut[39] = 16'sd0;
        ecg_lut[40] = 16'sd0;   ecg_lut[41] = 16'sd0;   ecg_lut[42] = 16'sd0;   ecg_lut[43] = -16'sd1;
        ecg_lut[44] = -16'sd2;  ecg_lut[45] = 16'sd3;   ecg_lut[46] = 16'sd33;  ecg_lut[47] = 16'sd112;
        ecg_lut[48] = 16'sd244; ecg_lut[49] = 16'sd377; ecg_lut[50] = 16'sd430; ecg_lut[51] = 16'sd361;
        ecg_lut[52] = 16'sd219; ecg_lut[53] = 16'sd90;  ecg_lut[54] = 16'sd20;  ecg_lut[55] = 16'sd0;
        ecg_lut[56] = 16'sd2;   ecg_lut[57] = 16'sd9;   ecg_lut[58] = 16'sd15;  ecg_lut[59] = 16'sd21;
        ecg_lut[60] = 16'sd28;  ecg_lut[61] = 16'sd35;  ecg_lut[62] = 16'sd43;  ecg_lut[63] = 16'sd53;
        ecg_lut[64] = 16'sd62;  ecg_lut[65] = 16'sd73;  ecg_lut[66] = 16'sd83;  ecg_lut[67] = 16'sd93;
        ecg_lut[68] = 16'sd102; ecg_lut[69] = 16'sd109; ecg_lut[70] = 16'sd115; ecg_lut[71] = 16'sd119;
        ecg_lut[72] = 16'sd120; ecg_lut[73] = 16'sd119; ecg_lut[74] = 16'sd115; ecg_lut[75] = 16'sd109;
        ecg_lut[76] = 16'sd102; ecg_lut[77] = 16'sd93;  ecg_lut[78] = 16'sd83;  ecg_lut[79] = 16'sd73;
        ecg_lut[80] = 16'sd62;  ecg_lut[81] = 16'sd53;  ecg_lut[82] = 16'sd43;  ecg_lut[83] = 16'sd35;
        ecg_lut[84] = 16'sd28;  ecg_lut[85] = 16'sd21;  ecg_lut[86] = 16'sd16;  ecg_lut[87] = 16'sd12;
        ecg_lut[88] = 16'sd9;   ecg_lut[89] = 16'sd6;   ecg_lut[90] = 16'sd4;   ecg_lut[91] = 16'sd3;
        ecg_lut[92] = 16'sd2;   ecg_lut[93] = 16'sd1;   ecg_lut[94] = 16'sd1;   ecg_lut[95] = 16'sd1;
        ecg_lut[96] = 16'sd0;   ecg_lut[97] = 16'sd0;   ecg_lut[98] = 16'sd0;   ecg_lut[99] = 16'sd0;
    end

    initial fp = $fopen("hybrid_lms_error.txt","w");
    always @(posedge clk) $fdisplay(fp,"%0d",e_out);

    //--------------------------------------------------
    // Mode / mu statistics Tracking Modules
    //--------------------------------------------------
    integer total_cycles;
    integer lms_count;
    integer signlms_count;
    integer mu_sum;
    integer mu_min;
    integer mu_max;
    integer stats_fp;

    integer SETTLE_CYCLES;     
    integer steady_cycles;
    integer steady_lms_count;
    integer steady_signlms_count;
    integer steady_mu_sum;
    integer steady_mu_min;
    integer steady_mu_max;

    initial begin
        total_cycles  = 0;
        lms_count     = 0;
        signlms_count = 0;
        mu_sum        = 0;
        mu_min        = 999;
        mu_max        = 0;
        SETTLE_CYCLES         = 10000;  
        steady_cycles         = 0;
        steady_lms_count      = 0;
        steady_signlms_count  = 0;
        steady_mu_sum         = 0;
        steady_mu_min         = 999;
        steady_mu_max         = 0;
    end

    always @(posedge clk)
    begin
        if (!rst)
        begin
            total_cycles = total_cycles + 1;
            if (DUT.LMS60.mode_select == 1'b0)
                lms_count = lms_count + 1;
            else
                signlms_count = signlms_count + 1;
                
            mu_sum = mu_sum + DUT.LMS60.mu_dynamic;
            if (DUT.LMS60.mu_dynamic < mu_min) mu_min = DUT.LMS60.mu_dynamic;
            if (DUT.LMS60.mu_dynamic > mu_max) mu_max = DUT.LMS60.mu_dynamic;

            if (total_cycles > SETTLE_CYCLES)
            begin
                steady_cycles = steady_cycles + 1;
                if (DUT.LMS60.mode_select == 1'b0)
                    steady_lms_count = steady_lms_count + 1;
                else
                    steady_signlms_count = steady_signlms_count + 1;
                steady_mu_sum = steady_mu_sum + DUT.LMS60.mu_dynamic;
                if (DUT.LMS60.mu_dynamic < steady_mu_min) steady_mu_min = DUT.LMS60.mu_dynamic;
                if (DUT.LMS60.mu_dynamic > steady_mu_max) steady_mu_max = DUT.LMS60.mu_dynamic;
            end
        end
    end

    //--------------------------------------------------
    // Reference Waveform Generation Logic
    //--------------------------------------------------
    initial
    begin
        rst  = 1;
        x_in = 0;
        d_in = 0;
        idx  = 0;
        becg = 0;
        #20;
        rst = 0;
        forever
        begin
            x_in = $signed(sine_lut[idx]) - 8'sd128;
            d_in = ecg_lut[becg] + (x_in <<< 3);
            idx = idx + 1;
            if(idx == 64)
            begin
                idx  = 0;
                becg = becg + 1;
                if(becg == 100)
                    becg = 0;
            end
            #40;   
        end
    end

    initial
    begin
        #500000;
    
        $fclose(fp);
    
        stats_fp = $fopen("mode_stats.txt","w");
    
        // Console output
        $display("==================================================");
        $display(" FULL-RUN statistics (includes startup transient)");
        $display("==================================================");
        $display(" Total clock cycles sampled : %0d", total_cycles);
        $display(" LMS mode cycles            : %0d (%0.2f%%)",
                 lms_count,
                 (lms_count*100.0)/total_cycles);
        $display(" Sign-LMS mode cycles       : %0d (%0.2f%%)",
                 signlms_count,
                 (signlms_count*100.0)/total_cycles);
        $display(" mu_min / mu_max / mu_avg   : %0d / %0d / %0.3f",
                 mu_min,
                 mu_max,
                 mu_sum*1.0/total_cycles);
    
        $display("==================================================");
        $display(" STEADY-STATE statistics (first %0d cycles skipped)",
                 SETTLE_CYCLES);
        $display("==================================================");
        $display(" Total clock cycles sampled : %0d", steady_cycles);
        $display(" LMS mode cycles            : %0d (%0.2f%%)",
                 steady_lms_count,
                 (steady_lms_count*100.0)/steady_cycles);
        $display(" Sign-LMS mode cycles       : %0d (%0.2f%%)",
                 steady_signlms_count,
                 (steady_signlms_count*100.0)/steady_cycles);
        $display(" mu_min / mu_max / mu_avg   : %0d / %0d / %0.3f",
                 steady_mu_min,
                 steady_mu_max,
                 steady_mu_sum*1.0/steady_cycles);
    
        // File output
        $fdisplay(stats_fp,"==================================================");
        $fdisplay(stats_fp,"FULL-RUN STATISTICS");
        $fdisplay(stats_fp,"==================================================");
        $fdisplay(stats_fp,"TOTAL_CYCLES=%0d", total_cycles);
        $fdisplay(stats_fp,"LMS_UTIL=%0.4f",
                  (lms_count*100.0)/total_cycles);
        $fdisplay(stats_fp,"SIGNLMS_UTIL=%0.4f",
                  (signlms_count*100.0)/total_cycles);
        $fdisplay(stats_fp,"MU_MIN=%0d", mu_min);
        $fdisplay(stats_fp,"MU_MAX=%0d", mu_max);
        $fdisplay(stats_fp,"MU_AVG=%0.4f",
                  mu_sum*1.0/total_cycles);
    
        $fdisplay(stats_fp,"");
    
        $fdisplay(stats_fp,"==================================================");
        $fdisplay(stats_fp,"STEADY STATE STATISTICS");
        $fdisplay(stats_fp,"==================================================");
        $fdisplay(stats_fp,"STEADY_CYCLES=%0d", steady_cycles);
        $fdisplay(stats_fp,"STEADY_LMS_UTIL=%0.4f",
                  (steady_lms_count*100.0)/steady_cycles);
        $fdisplay(stats_fp,"STEADY_SIGNLMS_UTIL=%0.4f",
                  (steady_signlms_count*100.0)/steady_cycles);
        $fdisplay(stats_fp,"STEADY_MU_MIN=%0d",
                  steady_mu_min);
        $fdisplay(stats_fp,"STEADY_MU_MAX=%0d",
                  steady_mu_max);
        $fdisplay(stats_fp,"STEADY_MU_AVG=%0.4f",
                  steady_mu_sum*1.0/steady_cycles);
    
        $fclose(stats_fp);
    
        $finish;
    end
endmodule
