/* TODO: name and PennKeys of all group members here
 *
 * lc4_single.v
 * Implements a single-cycle data path
 *
 */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // Main clock
    input  wire        rst,                // Global reset
    input  wire        gwe,                // Global we for single-step clock
   
    output wire [15:0] o_cur_pc,           // Address to read from instruction memory
    input  wire [15:0] i_cur_insn,         // Output of instruction memory
    output wire [15:0] o_dmem_addr,        // Address to read/write from/to data memory; SET TO 0x0000 FOR NON LOAD/STORE INSNS
    input  wire [15:0] i_cur_dmem_data,    // Output of data memory
    output wire        o_dmem_we,          // Data memory write enable
    output wire [15:0] o_dmem_towrite,     // Value to write to data memory

    // Testbench signals are used by the testbench to verify the correctness of your datapath.
    // Many of these signals simply export internal processor state for verification (such as the PC).
    // Some signals are duplicate output signals for clarity of purpose.
    //
    // Don't forget to include these in your schematic!

    output wire [1:0]  test_stall,         // Testbench: is this a stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc,        // Testbench: program counter
    output wire [15:0] test_cur_insn,      // Testbench: instruction bits
    output wire        test_regfile_we,    // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel,  // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data,  // Testbench: value to write into the register file
    output wire        test_nzp_we,        // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits,  // Testbench: value to write to NZP bits
    output wire        test_dmem_we,       // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr,     // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data,     // Testbench: value read/writen from/to memory
   
    input  wire [7:0]  switch_data,        // Current settings of the Zedboard switches
    output wire [7:0]  led_data            // Which Zedboard LEDs should be turned on?
   );

   // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   assign led_data = switch_data;

   wire [ 2:0] rssel;              // rs
   wire        rsre;               // does this instruction read from rs?
   wire [ 2:0] rtsel;              // rt
   wire        rtre;               // does this instruction read from rt?
   wire [ 2:0] rdsel;               // rd
   wire        regfile_we;         // does this instruction write to rd?
   wire        nzp_we;             // does this instruction write the NZP bits?
   wire        select_pc_plus_one; // write PC+1 to the regfile?
   wire        is_load;            // is this a load instruction?
   wire        is_store;           // is this a store instruction?
   wire        is_branch;          // is this a branch instruction?
   wire        is_control_insn;     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?

   wire [15:0] alu_rs_input;
   wire [15:0] alu_rt_input;
   wire [15:0] alu_rd_output;

   wire [15:0] regfile_rs_output;
   wire [15:0] regfile_rt_output;
   wire [15:0] regfile_rd_input;


    assign o_dmem_towrite = (is_store == 1'b1) ? regfile_rt_output : 16'h0000;
    assign o_dmem_we = is_store;//(is_store == 1'b1) ?1'b1 : 1'b0; 

    assign o_dmem_addr = (is_store == 1'b1 || 
                          is_load == 1'b1) ? alu_rd_output : 
                                             16'h0000; // Value to write to data memory


    //assign test_stall = 2'b00;         // Testbench: is this a stall cycle? (don't compare the test values)
    assign test_cur_pc              = pc;        // Testbench: program counter
    assign test_cur_insn            = i_cur_insn;      // Testbench: instruction bits
    assign test_regfile_we          = regfile_we;    // Testbench: register file write enable
    assign test_regfile_wsel        = rdsel;  // Testbench: which register to write in the register file 
    assign test_regfile_data        = regfile_rd_input;  // Testbench: value to write into the register file
    assign test_nzp_we              = nzp_we;        // Testbench: NZP condition codes write enable
    assign test_nzp_new_bits        = nzp_in;  // Testbench: value to write to NZP bits
    assign test_dmem_we             = is_store;       // Testbench: data memory write enable
    assign test_dmem_addr           = o_dmem_addr;     // Testbench: address to read/write memory
    assign test_dmem_data           = (is_store == 1'b1) ? o_dmem_towrite :
                                      (is_load  == 1'b1) ? i_cur_dmem_data : 16'h0000;     // Testbench: value read/writen from/to memory


   cla16 pcInc(.a(pc), .b(16'h0001), .cin(1'b0), .sum(pc_adder_out));

   wire [15:0] pc_adder_out;

  // assign next_pc = (is_branch == 1'b1 || is_control_insn == 1'b1) ? o_cur_pc : pc_adder_out;

  assign o_cur_pc = pc; 

  assign next_pc =   (i_cur_insn[15:9]    == 7'b0000000 && (nzp_out == 3'b000)) ||  // NOP
                     (i_cur_insn[15:9]   == 7'b0000001 && nzp_out == 3'b001)||  //BRp
                     (i_cur_insn[15:9]   == 7'b0000010 && nzp_out == 3'b010)||  //BRz
                     (i_cur_insn[15:9]   == 7'b0000011 && (nzp_out==3'b010 || nzp_out==3'b001))||  //BRzp
                     (i_cur_insn[15:9]   == 7'b0000100 && nzp_out == 3'b100)||  //BRn
                     (i_cur_insn[15:9]   == 7'b0000101 && (nzp_out==3'b100 || nzp_out==3'b001))|| //BRnp
                     (i_cur_insn[15:9]   == 7'b0000110 && (nzp_out==3'b010 || nzp_out==3'b100))|| //BRnz
                     (i_cur_insn[15:9]   == 7'b0000111 && (nzp_out==3'b010 || nzp_out==3'b001 || nzp_out==3'b100))|| //BRnzp
                     (i_cur_insn[15:11]  == 5'b01001  || // JSR
                      i_cur_insn[15:11]  == 5'b11001  || // JMP
                      i_cur_insn[15:11]  == 5'b11000  || // JMPR
                      i_cur_insn[15:12]  == 4'b1111)  || // TRAP
                     (i_cur_insn[15:11]  == 5'b01000   ||  // JSRR
                      i_cur_insn[15:11]  == 5'b11000)  ||  // JMPR
                     (i_cur_insn[15:12]  == 4'b1000)?  alu_rd_output :  // RTI
                                                      pc_adder_out;        // Default 

  //  assign o_cur_pc = ( i_cur_insn[15:9]  == 7'b0000000 ||  // NOP
  //                      i_cur_insn[15:12] == 4'b0001    ||  // ADD, MUL, SUB, DIV, ADDI
  //                      i_cur_insn[15:12] == 4'b0010    ||  // CMP, CMPI, CMPU, CMPIU
  //                      i_cur_insn[15:12] == 4'b0101    ||  // AND, NOT, OR, XOR, ANDI
  //                      i_cur_insn[15:13] == 3'b011     ||  // LDR, STR
  //                      i_cur_insn[15:12] == 4'b1010    ||  // SLL, SRA, SRL, MOD
  //                      i_cur_insn[15:12] == 4'b1001    ||  // CONST
  //                      i_cur_insn[15:12] == 4'b1101)   ?  pc : // HICONST

  //                    (i_cur_insn[15:9]  == 7'b0000001 && nzp_in == 3'b001)||  //BRp
  //                    (i_cur_insn[15:9]  == 7'b0000010 && nzp_out == 3'b010)||  //BRz
  //                    (i_cur_insn[15:9]  == 7'b0000011 && (nzp_out==3'b010 || nzp_out==3'b001))||  //BRzp
  //                    (i_cur_insn[15:9]  == 7'b0000100 && nzp_out == 3'b100)||  //BRn
  //                    (i_cur_insn[15:9]  == 7'b0000101 && (nzp_out==3'b100 || nzp_out==3'b001))|| //BRnp
  //                    (i_cur_insn[15:9]  == 7'b0000110 && (nzp_out==3'b010 || nzp_out==3'b100))|| //BRnz
  //                    (i_cur_insn[15:9]  == 7'b0000111 && (nzp_out==3'b010 || nzp_out==3'b001 || nzp_out==3'b100))|| //BRnzp
  //                    (i_cur_insn[15:12]  == 5'b01001  || // JSR
  //                    i_cur_insn[15:11]  == 5'b11001  || // JMP
  //                    i_cur_insn[15:12]  == 4'b1111)  ?  alu_rd_output :  // TRAP

  //                    (i_cur_insn[15:11] == 5'b01000  ||  // JSRR
  //                    i_cur_insn[15:11] == 5'b11000) ?  regfile_rs_output :  // JMPR
  //                                                     pc_adder_out;        // Default 

   lc4_decoder decoder( .insn(i_cur_insn),               // instruction input  wire [15:0] 
                        .r1sel(rssel),              // rs
                        .r1re(rsre),               // does this instruction read from rs?
                        .r2sel(rtsel),              // rt
                        .r2re(rtre),               // does this instruction read from rt?
                        .wsel(rdsel),               // rd
                        .regfile_we(regfile_we),         // does this instruction write to rd?
                        .nzp_we(nzp_we),             // does this instruction write the NZP bits?
                        .select_pc_plus_one(select_pc_plus_one), // write PC+1 to the regfile?
                        .is_load(is_load),            // is this a load instruction?
                        .is_store(is_store),           // is this a store instruction?
                        .is_branch(is_branch),          // is this a branch instruction?
                        .is_control_insn(is_control_insn)     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
                     );

   lc4_regfile #(16) regfile( .clk(clk),
                              .gwe(gwe),
                              .rst(rst),
                              .i_rs(rssel),      // rs selector
                              .o_rs_data(regfile_rs_output), // rs contents
                              .i_rt(rtsel),      // rt selector
                              .o_rt_data(regfile_rt_output), // rt contents
                              .i_rd(rdsel),      // rd selector
                              .i_wdata(regfile_rd_input) ,// data to write
                              .i_rd_we(regfile_we)    // write enable
                            );



   assign regfile_rd_input = (is_load == 1'b1) ? i_cur_dmem_data : 
                             (select_pc_plus_one == 1'b1)  ? pc_adder_out : 
                                                                  alu_rd_output;

   assign alu_rs_input = regfile_rs_output;

   assign alu_rt_input = regfile_rt_output;


   lc4_alu alu(.i_insn(i_cur_insn),
               .i_pc(pc),
               .i_r1data(alu_rs_input),
               .i_r2data(alu_rt_input),
               .o_result(alu_rd_output));

   
   wire [2:0] nzp_in;
   assign  nzp_in =  (regfile_rd_input[15]   == 1'b1) ? 3'b100 :       // N
                     (regfile_rd_input[15:0] == 16'b0) ? 3'b010 :       // Z
                       (regfile_rd_input[15] == 1'b1)? 3'b001:        // P
                                                         3'b000;


   wire[2:0] nzp_out;


   Nbit_reg #(3, 3'b000) nzp_reg (.in(nzp_in), .out(nzp_out), .clk(clk), .we(nzp_we), .gwe(gwe), .rst(rst));

   /* DO NOT MODIFY THIS CODE */
   // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)
   assign test_stall = 2'b0; 

   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   /* END DO NOT MODIFY THIS CODE */


   /*******************************
    * TODO: INSERT YOUR CODE HERE *
    *******************************/



   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    * 
    * To disable the entire block add the statement
    * `define NDEBUG
    * to the top of your file.  We also define this symbol
    * when we run the grading scripts.
    */
`ifndef NDEBUG
   always @(posedge gwe) begin
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nano-seconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecial.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      // $display();
   end
`endif
endmodule
