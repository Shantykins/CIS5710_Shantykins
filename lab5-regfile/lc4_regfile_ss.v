`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

/* 8-register, n-bit register file with
 * four read ports and two write ports
 * to support two pipes.
 * 
 * If both pipes try to write to the
 * same register, pipe B wins.
 * 
 * Inputs should be bypassed to the outputs
 * as needed so the register file returns
 * data that is written immediately
 * rather than only on the next cycle.
 */
module lc4_regfile_ss #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,

    input  wire [  2:0] i_rs_A,      // pipe A: rs selector
    output wire [n-1:0] o_rs_data_A, // pipe A: rs contents
    input  wire [  2:0] i_rt_A,      // pipe A: rt selector
    output wire [n-1:0] o_rt_data_A, // pipe A: rt contents

    input  wire [  2:0] i_rs_B,      // pipe B: rs selector
    output wire [n-1:0] o_rs_data_B, // pipe B: rs contents
    input  wire [  2:0] i_rt_B,      // pipe B: rt selector
    output wire [n-1:0] o_rt_data_B, // pipe B: rt contents

    input  wire [  2:0]  i_rd_A,     // pipe A: rd selector
    input  wire [n-1:0]  i_wdata_A,  // pipe A: data to write
    input  wire          i_rd_we_A,  // pipe A: write enable

    input  wire [  2:0]  i_rd_B,     // pipe B: rd selector
    input  wire [n-1:0]  i_wdata_B,  // pipe B: data to write
    input  wire          i_rd_we_B   // pipe B: write enable
    );

   /*** TODO: Your Code Here ***/

    wire [n-1:0] r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v;
    wire [n-1:0] i_wd_data_0, i_wd_data_1, i_wd_data_2, i_wd_data_3, i_wd_data_4, i_wd_data_5, i_wd_data_6, i_wd_data_7;

    wire [n-1:0] o_rs_out_A, o_rt_out_A, o_rs_out_B, o_rt_out_B;

    wire [7:0] regWriteSelector_pA, regWriteSelector_pB; 

    wire [7:0] i_rd_we;

    decoder_3_to_8 decA(.rdsel(i_rd_A), .writeSelectors(regWriteSelector_pA));
    decoder_3_to_8 decB(.rdsel(i_rd_B), .writeSelectors(regWriteSelector_pB));

    genvar i; 

    for(i = 0; i < 8; i = i + 1) begin
     assign i_rd_we[i] = (regWriteSelector_pB[i] && i_rd_we_B) || (regWriteSelector_pA[i] && i_rd_we_A);
     
     //(regWriteSelector_pB[i] == 1'b1) ? i_rd_we_B :
                         //(regWriteSelector_pA[i] == 1'b1) ? i_rd_we_A :
                         //                                   1'b0;
   end

    assign i_wd_data_0 = (regWriteSelector_pB[0] == 1'b1 && i_rd_we_B ) ? i_wdata_B : 
                        (regWriteSelector_pA[0] == 1'b1 && i_rd_we_A) ? i_wdata_A : 16'b0;
    
    assign i_wd_data_1 = (regWriteSelector_pB[1] == 1'b1 && i_rd_we_B) ? i_wdata_B : 
                        (regWriteSelector_pA[1] == 1'b1 && i_rd_we_A) ? i_wdata_A : 16'b0;
    
    assign i_wd_data_2 = (regWriteSelector_pB[2] == 1'b1 && i_rd_we_B) ? i_wdata_B : 
                        (regWriteSelector_pA[2] == 1'b1 && i_rd_we_A) ? i_wdata_A : 16'b0;
    
    assign i_wd_data_3 = (regWriteSelector_pB[3] == 1'b1 && i_rd_we_B) ? i_wdata_B : 
                        (regWriteSelector_pA[3] == 1'b1 && i_rd_we_A) ? i_wdata_A : 16'b0;
    
    assign i_wd_data_4 = (regWriteSelector_pB[4] == 1'b1 && i_rd_we_B) ? i_wdata_B : 
                        (regWriteSelector_pA[4] == 1'b1 && i_rd_we_A) ? i_wdata_A : 16'b0;
    
    assign i_wd_data_5 = (regWriteSelector_pB[5] == 1'b1 && i_rd_we_B) ? i_wdata_B : 
                        (regWriteSelector_pA[5] == 1'b1 && i_rd_we_A) ? i_wdata_A : 16'b0;
    
    assign i_wd_data_6 = (regWriteSelector_pB[6] == 1'b1 && i_rd_we_B) ? i_wdata_B : 
                        (regWriteSelector_pA[6] == 1'b1 && i_rd_we_A) ? i_wdata_A : 16'b0;
    
    assign i_wd_data_7 = (regWriteSelector_pB[7] == 1'b1 && i_rd_we_B) ? i_wdata_B : 
                        (regWriteSelector_pA[7] == 1'b1 && i_rd_we_A) ? i_wdata_A : 16'b0;

    Nbit_reg #(n) r0 (.out(r0v), .in(i_wd_data_0), .we(i_rd_we[0]), .gwe(gwe), .rst(rst), .clk(clk));
    Nbit_reg #(n) r1 (.out(r1v), .in(i_wd_data_1), .we(i_rd_we[1]), .gwe(gwe), .rst(rst), .clk(clk));
    Nbit_reg #(n) r2 (.out(r2v), .in(i_wd_data_2), .we(i_rd_we[2]), .gwe(gwe), .rst(rst), .clk(clk));
    Nbit_reg #(n) r3 (.out(r3v), .in(i_wd_data_3), .we(i_rd_we[3]), .gwe(gwe), .rst(rst), .clk(clk));
    Nbit_reg #(n) r4 (.out(r4v), .in(i_wd_data_4), .we(i_rd_we[4]), .gwe(gwe), .rst(rst), .clk(clk));
    Nbit_reg #(n) r5 (.out(r5v), .in(i_wd_data_5), .we(i_rd_we[5]), .gwe(gwe), .rst(rst), .clk(clk));
    Nbit_reg #(n) r6 (.out(r6v), .in(i_wd_data_6), .we(i_rd_we[6]), .gwe(gwe), .rst(rst), .clk(clk));
    Nbit_reg #(n) r7 (.out(r7v), .in(i_wd_data_7), .we(i_rd_we[7]), .gwe(gwe), .rst(rst), .clk(clk));

    Nbit_mux8to1 #(n) mux_rs_A (.sel(i_rs_A), .out(o_rs_out_A), .in0(r0v), .in1(r1v), .in2(r2v), .in3(r3v), 
                            .in4(r4v), .in5(r5v), .in6(r6v), .in7(r7v));
    Nbit_mux8to1 #(n) mux_rt_A (.sel(i_rt_A), .out(o_rt_out_A), .in0(r0v), .in1(r1v), .in2(r2v), .in3(r3v), 
                            .in4(r4v), .in5(r5v), .in6(r6v), .in7(r7v));

    Nbit_mux8to1 #(n) mux_rs_B (.sel(i_rs_B), .out(o_rs_out_B), .in0(r0v), .in1(r1v), .in2(r2v), .in3(r3v), 
                            .in4(r4v), .in5(r5v), .in6(r6v), .in7(r7v));
    Nbit_mux8to1 #(n) mux_rt_B (.sel(i_rt_B), .out(o_rt_out_B), .in0(r0v), .in1(r1v), .in2(r2v), .in3(r3v), 
                            .in4(r4v), .in5(r5v), .in6(r6v), .in7(r7v));

    assign o_rs_data_A =    (i_rs_A == i_rd_B && i_rd_we_B == 1'b1) ? i_wdata_B :
                            (i_rs_A == i_rd_A && i_rd_we_A == 1'b1) ? i_wdata_A : 
                                                                      o_rs_out_A;

    assign o_rt_data_A =    (i_rt_A == i_rd_B && i_rd_we_B == 1'b1) ? i_wdata_B :
                            (i_rt_A == i_rd_A && i_rd_we_A == 1'b1) ? i_wdata_A : 
                                                                      o_rt_out_A;
    
    assign o_rs_data_B = (i_rs_B == i_rd_B && i_rd_we_B == 1'b1) ?  i_wdata_B :
                         (i_rs_B == i_rd_A  && i_rd_we_A == 1'b1) ? i_wdata_A : 
                                                                    o_rs_out_B;

    assign o_rt_data_B = (i_rt_B == i_rd_B && i_rd_we_B == 1'b1) ?  i_wdata_B :
                         (i_rt_B == i_rd_A  && i_rd_we_A == 1'b1) ? i_wdata_A :
                                                                    o_rt_out_B;

endmodule

module Nbit_mux8to1 #(parameter n=1)
   (input  wire [2:0] sel,
    output wire [n-1:0] out, 
    input wire [n-1:0] in0, in1, in2, in3, in4, in5, in6, in7);

    assign out = (sel == 3'd0) ? in0 : 
                 (sel == 3'd1) ? in1 :
                 (sel == 3'd2) ? in2 :  
                 (sel == 3'd3) ? in3 : 
                 (sel == 3'd4) ? in4 :
                 (sel == 3'd5) ? in5 :
                 (sel == 3'd6) ? in6 : 
                 in7;

endmodule

module  decoder_3_to_8 (
    input wire [2:0] rdsel ,
    output wire [7:0] writeSelectors);

    assign writeSelectors = (rdsel == 3'd0) ? 8'd1   : 
                            (rdsel == 3'd1) ? 8'd2   : 
                            (rdsel == 3'd2) ? 8'd4   : 
                            (rdsel == 3'd3) ? 8'd8   : 
                            (rdsel == 3'd4) ? 8'd16  : 
                            (rdsel == 3'd5) ? 8'd32  : 
                            (rdsel == 3'd6) ? 8'd64  :  
                            8'd128;

endmodule
