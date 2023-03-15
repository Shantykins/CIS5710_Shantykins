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
   (input  wire        clk,                // Main clock
    input  wire        rst,                // Global reset
    input  wire        gwe,                // Global we for single-step clock
   
    output wire [15:0] o_cur_pc,           // Address to read from instruction memory
    input  wire [15:0] i_cur_insn,         // Output of instruction memory
    output wire [15:0] o_dmem_addr,        // Address to read/write from/to data memory; SET TO 0x0000 FOR NON LOAD/STORE INSNS
    input  wire [15:0] i_cur_dmem_data,    // Output of data memory
    output wire        o_dmem_we,          // Data memory write enable
    output wire [15:0] o_dmem_towrite,     // Value to write to data memory

    // Testbench signals are used by the testbench to verify the correctness of your datapath.
    // Many of these signals simply export internal processor state for verification (such as the PC).
    // Some signals are duplicate output signals for clarity of purpose.
    //
    // Don't forget to include these in your schematic!

    output wire [1:0]  test_stall,         // Testbench: is this a stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc,        // Testbench: program counter
    output wire [15:0] test_cur_insn,      // Testbench: instruction bits
    output wire        test_regfile_we,    // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel,  // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data,  // Testbench: value to write into the register file
    output wire        test_nzp_we,        // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits,  // Testbench: value to write to NZP bits
    output wire        test_dmem_we,       // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr,     // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data,     // Testbench: value read/writen from/to memory
   
    input  wire [7:0]  switch_data,        // Current settings of the Zedboard switches
    output wire [7:0]  led_data            // Which Zedboard LEDs should be turned on?
    );

   // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   assign led_data = switch_data;

   
   /* DO NOT MODIFY THIS CODE */
   // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)
   assign test_stall = 2'b0; 

   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   /* END DO NOT MODIFY THIS CODE */

   /*******************************
    * TODO: INSERT YOUR CODE HERE *
    *******************************/
   wire [15:0] r1data;
   wire [15:0] r2data;
   wire signed [15:0] out_alu;
   wire [2:0] r1sel;
   wire r1re;
   wire [2:0] r2sel;
   wire r2re;
   wire [2:0] wsel;
   wire regfile_we;
   wire nzp_we;
   wire select_pc_plus_one;
   wire is_load;
   wire is_store;
   wire is_branch;
   wire is_control_insn;
   wire [2:0] nzp_reg;
   wire [2:0] nzp_reg_out;
   wire [15:0] pc_sum;
   wire [15:0] reg_data_in;

   ///////Decoder for isntruction Parsing/////////////
   lc4_decoder dec1(.insn(i_cur_insn),
                    .r1sel(r1sel),
                    .r1re(r1re),
                    .r2sel(r2sel),
                    .r2re(r2re),
                    .wsel(wsel),
                    .regfile_we(regfile_we),
                    .nzp_we(nzp_we),
                    .select_pc_plus_one(select_pc_plus_one),
                    .is_load(is_load),
                    .is_store(is_store),
                    .is_branch(is_branch),
                    .is_control_insn(is_control_insn));
   /////////////////////////////////////////////////////

   /////////// Main ALU Block//////////////
   lc4_alu ALU1(.i_insn(i_cur_insn),
               .i_pc(pc),
               .i_r1data(r1data),
               .i_r2data(r2data),
               .o_result(out_alu));
   ///////////////////////////////////////

   /////////////////////REGFILE//////////////////////////
   lc4_regfile regf(.clk(clk),
                    .gwe(gwe),
                    .rst(rst),
                    .i_rs(r1sel), 
                    .o_rs_data(r1data),
                    .i_rt(r2sel),
                    .o_rt_data(r2data),
                    .i_rd(wsel), // It is either wsel or d'7
                    .i_wdata(reg_data_in), // it is either out_alu or pc+1 based on select_pc_plus_one. This signal decides if PC is to be stored
                    .i_rd_we(regfile_we));
   ///////////////////////////////////////////////////////

   /////////////i_wdata////////////////////////////////
   assign reg_data_in = (select_pc_plus_one == 1)?pc_sum : 
                        (is_load == 1)?i_cur_dmem_data:
                        out_alu;
   ///////////////////////////////////////////////////

   ////////////////////NZP Register//////////////////////
   Nbit_reg #(3) nzp_reg_1(.in(nzp_reg), .out(nzp_reg_out), .clk(clk), .we(nzp_we), .gwe(gwe), .rst(rst));
   /////////////////////////////////////////////////////

   //////////PC Increment Module/////////////////////////
   cla16 pc_inc(.a(pc),.b(16'h0001),.cin(1'b0),.sum(pc_sum));
   assign o_cur_pc = pc;
   ///////////////////////////////////////////////////////////

   /////////////////////////////// NZP Reg Tester /////////////////////////////////////////////////////////////////

   assign nzp_reg = (reg_data_in[15]==1'b1)?3'b100:
                    (reg_data_in[15:0]==16'b0)?3'b010:
                    (reg_data_in[15]==0)?3'b001:
                    3'b000;

   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

   ////////////////// Branch Handling ////////////////////////////////////////////////////
   assign next_pc  = (i_cur_insn[15:9] == 7'b0000000 && (nzp_reg_out == 3'b000))? out_alu : //nop
                     (i_cur_insn[15:9] == 7'b0000001 && (nzp_reg_out[0] == 1'b1))? out_alu : //BRp
                     (i_cur_insn[15:9] == 7'b0000010 && (nzp_reg_out[1] == 1'b1))? out_alu : //BRz
                     (i_cur_insn[15:9] == 7'b0000011 && (nzp_reg_out[1] == 1'b1 || nzp_reg_out[0] == 1'b1 ))? out_alu : //BRzp
                     (i_cur_insn[15:9] == 7'b0000100 && (nzp_reg_out[2] == 1'b1))? out_alu : //BRn
                     (i_cur_insn[15:9] == 7'b0000101 && (nzp_reg_out[2] == 1'b1 || nzp_reg_out[0] == 1'b1 ))? out_alu : //BRnp
                     (i_cur_insn[15:9] == 7'b0000110 && (nzp_reg_out[2] == 1'b1 || nzp_reg_out[1] == 1'b1 ))? out_alu : //BRnz
                     (i_cur_insn[15:9] == 7'b0000111 && (nzp_reg_out[2] == 1'b1 || nzp_reg_out[1] == 1'b1 || nzp_reg_out[0] == 1'b1 ))? out_alu : //BRnzp
                     (is_control_insn == 3'b001 && i_cur_insn[15:11] == 5'b11001)? out_alu : //JMP
                     (is_control_insn == 3'b001 && i_cur_insn[15:11] == 5'b11000)? out_alu : //JMPR
                     (is_control_insn == 3'b001 && i_cur_insn[15:11] == 5'b01000)? out_alu : //JSRR
                     (is_control_insn == 3'b001 && i_cur_insn[15:12] == 4'b1111) ? out_alu : //TRAP
                     (is_control_insn == 3'b001 && i_cur_insn[15:11] == 5'b01001)? out_alu : //JSR
                     (i_cur_insn[15:12] == 4'b1000)?out_alu: // RTI instruction
                     pc_sum;

   //////////////////////////////////////////////////////////////////////////////////////

   assign o_dmem_towrite = (is_store == 1'b1)?r2data : 16'h0000;
   assign o_dmem_we = is_store;
   assign o_dmem_addr = (is_load == 1'b1||is_store == 1'b1)?out_alu : 16'h0000;
   assign test_cur_pc = pc;
   assign test_cur_insn = i_cur_insn;
   assign test_regfile_we  = regfile_we;
   assign test_regfile_wsel = wsel;
   assign test_regfile_data = reg_data_in;
   assign test_dmem_we  = is_store;
   assign test_nzp_we  = nzp_we;
   assign test_dmem_addr = (is_load == 1'b1||is_store == 1'b1)?out_alu : 16'h0000;
   assign test_nzp_new_bits = nzp_reg;
   assign test_dmem_data = (is_load == 1'b1)?i_cur_dmem_data : (is_store == 1'b1)?o_dmem_towrite: 16'h0000;

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
    * to the top of your file.  We also define this symbol
    * when we run the grading scripts.
    */

`ifndef NDEBUG
   always @(posedge gwe) begin
      //$display("%d %h %h %h %h", $time, test_cur_pc, out_alu, nzp_reg_out, reg_data_in);
      //$display("%d %h ", $time, out_alu);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
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

