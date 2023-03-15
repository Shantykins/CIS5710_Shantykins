/* Names:    Shantanu Sampath and Adwait Kulkarni
   Pennkey: shantz  and */

`timescale 1ns / 1ps
`default_nettype none


module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);

      /*** YOUR CODE HERE ***/

      wire [15:0] claA, claB, claSum, divQuot, divRem; 
      wire claCin; 

      wire signed [15:0] IMM9, IMM5, IMM6, IMM7, IMM11, IMM11_SEXT; 
      wire [15:0] UIMM7, UIMM4, UIMM8; 

      wire signed [15:0] signed_r1data = i_r1data;
      wire signed [15:0] signed_r2data = i_r2data;

      assign IMM11[10:0] = i_insn[10:0]; 
      assign IMM11[15:11] = 5'b00000; 

      assign IMM11_SEXT[10:0] = i_insn[10:0]; 
      assign IMM11_SEXT[15:11] = (i_insn[10] == 1'b1) ? 5'b11111 : 5'b00000; 

      assign IMM9[8:0] = i_insn[8:0]; 
      assign IMM9[15:9] = (i_insn[8] == 1'b1) ? 7'b1111111 : 7'b0000000; 

      assign IMM5[4:0] = i_insn[4:0]; 
      assign IMM5[15:5] = (i_insn[4] == 1'b1) ? 11'b11111111111 : 11'b00000000000; 

      assign IMM6[5:0]  = i_insn[5:0]; 
      assign IMM6[15:6] = (i_insn[5] == 1'b1) ? 10'b1111111111 : 10'b0000000000; 

      assign IMM7[6:0]  = i_insn[6:0]; 
      assign IMM7[15:7] = (i_insn[6] == 1'b1) ? 9'b111111111 : 9'b000000000; 

      assign UIMM4[3:0]  = i_insn[3:0]; 
      assign UIMM4[15:4] = 12'b000000000000;

      assign UIMM7[6:0]  = i_insn[6:0]; 
      assign UIMM7[15:7] = 9'b000000000;

      assign UIMM8[7:0]  = i_insn[7:0]; 
      assign UIMM8[15:8] = 8'b00000000;

      cla16 cla_mod(.a(claA), .b(claB), .cin(claCin), .sum(claSum));

      lc4_divider aluDiv(.i_dividend(i_r1data), .i_divisor(i_r2data), .o_quotient(divQuot), .o_remainder(divRem));

      assign claA = (i_insn[15:12] == 4'b0000) || (i_insn[15:11] == 5'b11001) ? i_pc : i_r1data; 

      assign claB = ((i_insn[15:12] == 4'b0001 && i_insn[5:3]==4'b010)) ? ~i_r2data : 
                     (i_insn[15:12] == 4'b0001 && i_insn[5:3]==4'b000)  ? i_r2data : 
                     (i_insn[15:12] == 4'b0000) ? IMM9 : 
                     (i_insn[15:12] == 4'b0001 && i_insn[5]==1'b1) ? IMM5 : 
                     (i_insn[15:11] == 5'b01000) ? 16'b0 : 
                     (i_insn[15:11] == 5'b11001) ? IMM11_SEXT :
                    (i_insn[15:13] == 3'b011) ? IMM6: 
                    
                    i_r2data; //Ones compliment if subtracting

      assign claCin = (i_insn[15:12] == 4'b0001 && i_insn[5:3]==4'b010) ||
                       (i_insn[15:12] == 4'b0000) ||
                       (i_insn[15:11] == 5'b11001) ? 1'b1 : 1'b0; //Add 1 to twos compliment r2data if subtraction

      assign o_result = ((i_insn[15:12] == 4'b0001 && i_insn[5:3]==4'b000) || (i_insn[15:12] == 4'b0000))? claSum :  //ADD
                        (i_insn[15:12] == 4'b0001 && i_insn[5:3]==4'b001) ? i_r1data * i_r2data :                    //ML
                        ((i_insn[15:12] == 4'b0001 && i_insn[5:3]==4'b010))? claSum :                                //SUBB
                        ((i_insn[15:12] == 4'b0001 && i_insn[5]==1'b1))? claSum :                                    //ADD I
                        (i_insn[15:12] == 4'b0001 && i_insn[5:3]==4'b011) ? divQuot :                                //DIV

                        (i_insn[15:12] == 4'b0010 && i_insn[8:7]==2'b00) ?                                           //CMP 
                          (signed_r1data > signed_r2data ? 16'b1 : (signed_r1data == signed_r2data ? 16'b0 : 16'hFFFF)) :
                        (i_insn[15:12] == 4'b0010 && i_insn[8:7]==2'b01) ?                                           //CMPU
                          (i_r1data > i_r2data ? 16'b1 : (i_r1data == i_r2data ? 16'b0 : 16'hFFFF)) :
                        (i_insn[15:12] == 4'b0010 && i_insn[8:7]==2'b10) ?                                           //CMPI
                          (signed_r1data > IMM7 ? 16'b1 : (signed_r1data == IMM7 ? 16'b0 : 16'hFFFF)) : 
                        ((i_insn[15:12] == 4'b0010 && i_insn[8:7]==2'b11) ?                                          //CMPIU
                          (i_r1data > UIMM7 ? 16'b1 : (i_r1data == UIMM7 ? 16'b0 : 16'hFFFF) ): 
                        
                        (i_insn[15:11] == 5'b01000) ? claSum :   // JSRR
                        (i_insn[15:11] == 5'b01001) ? ((i_pc & 16'h8000)  | (IMM11 << 4))   :                        // JSR


                        (i_insn[15:12] == 4'b0101 && i_insn[5:3]==4'b000) ? i_r1data & i_r2data :                    // AND
                        (i_insn[15:12] == 4'b0101 && i_insn[5:3]==4'b001) ? ~i_r1data :                              // NOT
                        (i_insn[15:12] == 4'b0101 && i_insn[5:3]==4'b010) ? i_r1data | i_r2data :                    // OR
                        (i_insn[15:12] == 4'b0101 && i_insn[5:3]==4'b011) ? i_r1data ^ i_r2data :                    // XOR
                        (i_insn[15:12] == 4'b0101 && i_insn[5]== 1'b1) ? i_r1data & IMM5 :                           // ANDI


                        (i_insn[15:13] == 3'b011) ? claSum :                                                        //LDR/STR

                        (i_insn[15:12] == 4'b1000) ? i_r1data :                                                     // RTI 

                        (i_insn[15:12] == 4'b1001) ? IMM9 :                                                         // CONST 


                        (i_insn[15:12] == 4'b1010 && i_insn[5:4]==2'b00) ? i_r1data << UIMM4 :                      //SLL
                        (i_insn[15:12] == 4'b1010 && i_insn[5:4]==2'b01) ? $signed(signed_r1data >>> UIMM4) :       //SRA
                        (i_insn[15:12] == 4'b1010 && i_insn[5:4]==2'b10) ? i_r1data >> UIMM4 :                      //SRL
                        (i_insn[15:12] == 4'b1010 && i_insn[5:4]==2'b11) ? divRem :                                 //MOD


                        (i_insn[15:11] == 5'b11000) ? i_r1data :                                                    // JMPR
                        (i_insn[15:11] == 5'b11001) ? claSum :                                                      // JMP

                        (i_insn[15:12] == 4'b1101) ? (i_r1data & 16'h00FF) | (UIMM8 << 8) :                         // HICONST

                        (i_insn[15:12] == 4'b1111) ? (16'h8000 | UIMM8)        :                                    // TRAP

                        (16'h0000));                                                                                //default


endmodule
