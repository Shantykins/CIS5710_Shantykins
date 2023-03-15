/* TODO: INSERT NAME AND PENNKEY HERE */

`timescale 1 ns / 1 ps
`default_nettype none

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals 
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits collectively generate a carry (ignoring cin)
 * @param pout whether these 4 bits collectively would propagate an incoming carry (ignoring cin)
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);

  assign gout = gin[3] | pin[3] & gin[2] | pin[3] & pin[2] & gin[1] | pin[3] & pin[2] & pin[1] & gin[0];

  assign pout = (& pin[3:0]); 

  assign cout[0] = gin[0] | pin[0] & cin;
  assign cout[1] = gin[1] | pin[1] & gin[0] | pin[1] & pin[0] & cin;
  assign cout[2] = gin[2] | pin[2] & gin[1] | pin[2] &  pin[1] & gin[0] | pin[2] &  pin[1] & pin[0] & cin;
endmodule

/**
 * 16-bit Carry-Lookahead Adder
 * @param a first input
 * @param b second input
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla16
  (input wire [15:0]  a, b,
   input wire         cin,
   output wire [15:0] sum);

   wire [15:0] g, p, carry;

   wire g15_0; 
   wire p15_0; 

   assign carry[0] = cin; 

   wire [3:0] g_grp, p_grp;
   wire [2:0] car_grp;

   assign carry[12] = car_grp[2]; 
   assign carry[8] = car_grp[1]; 
   assign carry[4] = car_grp[0]; 

   genvar i;

   for(i = 0; i < 16; i = i + 1) begin
      gp1 g_mod(.a(a[i]), .b(b[i]), .g(g[i]), .p(p[i]));
   end

    gp4 gp4_1(.gin(g[3:0]), .pin(p[3:0]), .cin(carry[0]), .gout(g_grp[0]), .pout(p_grp[0]), .cout(carry[3:1]));

    gp4 gp4_2(.gin(g[7:4]), .pin(p[7:4]), .cin(car_grp[0]), .gout(g_grp[1]), .pout(p_grp[1]), .cout(carry[7:5]));

    gp4 gp4_3(.gin(g[11:8]), .pin(p[11:8]), .cin(car_grp[1]), .gout(g_grp[2]), .pout(p_grp[2]), .cout(carry[11:9]));

    gp4 gp4_4(.gin(g[15:12]), .pin(p[15:12]), .cin(car_grp[2]), .gout(g_grp[3]), .pout(p_grp[3]), .cout(carry[15:13]));

    gp4 gp4_big(.gin(g_grp[3:0]), .pin(p_grp[3:0]), .cin(carry[0]), .gout(g15_0), .pout(p15_0), .cout(car_grp[2:0]));


   for(i = 0; i < 16; i = i + 1) begin
      assign sum[i] =  a[i] ^ b[i] ^ carry[i];
   end 


endmodule


/** Lab 2 Extra Credit, see details at
  https://github.com/upenn-acg/cis501/blob/master/lab2-alu/lab2-cla.md#extra-credit
 If you are not doing the extra credit, you should leave this module empty.
 */
module gpn
  #(parameter N = 4)
  (input wire [N-1:0] gin, pin,
   input wire  cin,
   output wire gout, pout,
   output wire [N-2:0] cout);


   wire [N-1:0] gArr, pArr; 

   assign gArr[0] = gin[0];

   assign cout[0] = cin;

   assign gout = gArr[N-1];
   assign pout = & pin[N-1 : 0]; 

   //
   // Calculate the Gs
   //

   genvar i; 

   for(i = 1; i < N; i = i + 1) begin

     assign gArr[i] = gin[i] | (gArr[i-1] & pin[i]);

   end

   for(i = 1; i < N - 1; i = i + 1) begin

      // assign cout[i] = gArr[i-1] | (& pin[i-1:0]) & cin;

      assign cout[i] = gin[i-1] | cout[i-1] & pin[i-1];
   
   end



 
endmodule
