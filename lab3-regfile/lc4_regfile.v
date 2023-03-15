/* TODO: Names of all group members
 * TODO: PennKeys of all group members
 *
 * lc4_regfile.v
 * Implements an 8-register register file parameterized on word size.
 *
 */

`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_regfile #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,
    input  wire [  2:0] i_rs,      // rs selector
    output wire [n-1:0] o_rs_data, // rs contents
    input  wire [  2:0] i_rt,      // rt selector
    output wire [n-1:0] o_rt_data, // rt contents
    input  wire [  2:0] i_rd,      // rd selector
    input  wire [n-1:0] i_wdata,   // data to write
    input  wire         i_rd_we    // write enable
    );

   /***********************
    * TODO YOUR CODE HERE *
    ***********************/

    wire [n-1:0] r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v;

    wire [7:0] regWriteSelectors;

    decoder_3_to_8 dec(.rdsel(i_rd), .writeSelectors(regWriteSelectors));

    Nbit_reg #(n) r0 (.out(r0v), .in(i_wdata), .we(regWriteSelectors[0] & i_rd_we), .gwe(gwe), .rst(rst), .clk(clk));
    Nbit_reg #(n) r1 (.out(r1v), .in(i_wdata), .we(regWriteSelectors[1] & i_rd_we), .gwe(gwe), .rst(rst), .clk(clk));
    Nbit_reg #(n) r2 (.out(r2v), .in(i_wdata), .we(regWriteSelectors[2] & i_rd_we), .gwe(gwe), .rst(rst), .clk(clk));
    Nbit_reg #(n) r3 (.out(r3v), .in(i_wdata), .we(regWriteSelectors[3] & i_rd_we), .gwe(gwe), .rst(rst), .clk(clk));
    Nbit_reg #(n) r4 (.out(r4v), .in(i_wdata), .we(regWriteSelectors[4] & i_rd_we), .gwe(gwe), .rst(rst), .clk(clk));
    Nbit_reg #(n) r5 (.out(r5v), .in(i_wdata), .we(regWriteSelectors[5] & i_rd_we), .gwe(gwe), .rst(rst), .clk(clk));
    Nbit_reg #(n) r6 (.out(r6v), .in(i_wdata), .we(regWriteSelectors[6] & i_rd_we), .gwe(gwe), .rst(rst), .clk(clk));
    Nbit_reg #(n) r7 (.out(r7v), .in(i_wdata), .we(regWriteSelectors[7] & i_rd_we), .gwe(gwe), .rst(rst), .clk(clk));
    
    Nbit_mux8to1 #(n) mux1 (.sel(i_rs), .out(o_rs_data), .in0(r0v), .in1(r1v), .in2(r2v), .in3(r3v), 
                            .in4(r4v), .in5(r5v), .in6(r6v), .in7(r7v));
    Nbit_mux8to1 #(n) mux2 (.sel(i_rt), .out(o_rt_data), .in0(r0v), .in1(r1v), .in2(r2v), .in3(r3v), 
                            .in4(r4v), .in5(r5v), .in6(r6v), .in7(r7v));
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



