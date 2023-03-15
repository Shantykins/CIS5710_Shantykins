/* 
      Name:       Shantanu Sampath
      Pennkey:    shantz
*/

`timescale 1ns / 1ps
`default_nettype none

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/

      wire [15:0] tmp_dividend[16:0];
      wire [15:0] tmp_remainder[16:0];
      wire [15:0] tmp_quotient[16:0];

      assign  o_quotient = (i_divisor == 16'b0) ? 16'b0 : tmp_quotient[16];
      assign o_remainder = (i_divisor == 16'b0) ? 16'b0 : tmp_remainder[16];


      assign tmp_dividend[0] = i_dividend;
      assign tmp_remainder[0] = 16'b0;
      assign tmp_quotient[0] = 16'b0;

      genvar i; 

      for(i = 0; i < 16; i = i + 1) begin
        
        lc4_divider_one_iter div(.i_dividend(tmp_dividend[i]), .i_divisor(i_divisor), .i_remainder(tmp_remainder[i]), 
                                 .i_quotient(tmp_quotient[i]), .o_dividend(tmp_dividend[i+1]), .o_remainder(tmp_remainder[i+1]),
                                 .o_quotient(tmp_quotient[i+1]));

      end


endmodule // lc4_divider

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient,
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/

    wire [15:0] remainder_tmp;

      assign remainder_tmp = (i_remainder << 1) | ((i_dividend >> 15) & 16'b1);
      
      assign o_quotient = (remainder_tmp < i_divisor) ? (i_quotient) << 1 : (i_quotient << 1) | 16'b1;

      assign o_remainder = (remainder_tmp < i_divisor) ? remainder_tmp : remainder_tmp - i_divisor;

      assign o_dividend = i_dividend << 1; 

endmodule
