/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // main clock
    input wire         rst, // global reset
    input wire         gwe, // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc, // Address to read from instruction memory
    input wire [15:0]  i_cur_insn, // Output of instruction memory
    output wire [15:0] o_dmem_addr, // Address to read/write from/to data memory
    input wire [15:0]  i_cur_dmem_data, // Output of data memory
    output wire        o_dmem_we, // Data memory write enable
    output wire [15:0] o_dmem_towrite, // Value to write to data memory
   
    output wire [1:0]  test_stall, // Testbench: is this is stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc, // Testbench: program counter
    output wire [15:0] test_cur_insn, // Testbench: instruction bits
    output wire        test_regfile_we, // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel, // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data, // Testbench: value to write into the register file
    output wire        test_nzp_we, // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits, // Testbench: value to write to NZP bits
    output wire        test_dmem_we, // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr, // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data, // Testbench: value read/writen from/to memory

    input wire [7:0]   switch_data, // Current settings of the Zedboard switches
    output wire [7:0]  led_data // Which Zedboard LEDs should be turned on?
    );
   
   /*** YOUR CODE HERE ***/

   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    * 
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    */

    //
    // TEST SIGNALS
    //

    assign led_data = switch_data;

   /*************************************************************************************
   *    FETCH STAGE
   *************************************************************************************/
   //==============================================================
   // REGISTER DECLARATION 
   // Registers: 
   // - Instruction Register(From IMEM)
   // - PC output from pc reg
   //==============================================================
   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // PC +1 adder
   cla16 pcInc(.a(pc), .b(16'h0001), .cin(1'b0), .sum(pc_adder_out));

   // Wire Declarations
   wire [15:0] next_pc;       // Input to PC reg after mux. 
   wire [15:0] pc;            // Output of PC Register
   wire [15:0] pc_adder_out;  // Output of PC + 1

   // Logic
   assign next_pc = pc_adder_out;  // Assign to cla out for ALU insns. TBD: CHANGE LATER

   //
   // TEST SIGNAL : PC
   //
   assign o_cur_pc =  pc;// Address to read from instruction memory

   /*************************************************************************************
   *    DECODE STAGE
   *************************************************************************************/
   //==============================================================
   // REGISTER DECLARATION 
   // Registers: 
   // - Instruction Register(From Fetch Stage IR)
   // - PC output from Fetch stage PC Reg
   //==============================================================

   // Pipeline Registers : PC
   Nbit_reg #(16, 16'h8200) decode_pc_pipeline_reg (.in(pc), .out(decode_pc_pipeline_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Fetch Instruction Register
   Nbit_reg #(16, 16'h0000) decode_ir_pipeline_reg (.in(i_cur_insn), .out(decode_ir_pipeline_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 

   //
   // DECODER INSTANTIATION
   //
   lc4_decoder decoder( .insn(decode_ir_pipeline_out),                   // instruction input  wire [15:0] 
                        .r1sel(decode_rssel),                            // rs
                        .r1re(decode_rsre),                              // does this instruction read from rs?
                        .r2sel(decode_rtsel),                            // rt
                        .r2re(decode_rtre),                              // does this instruction read from rt?
                        .wsel(decode_rdsel),                             // rd
                        .regfile_we(decode_regfile_we),                  // does this instruction write to rd?
                        .nzp_we(decode_nzp_we),                          // does this instruction write the NZP bits?
                        .select_pc_plus_one(decode_select_pc_plus_one),  // write PC+1 to the regfile?
                        .is_load(decode_is_load),                        // is this a load instruction?
                        .is_store(decode_is_store),                      // is this a store instruction?
                        .is_branch(decode_is_branch),                    // is this a branch instruction?
                        .is_control_insn(decode_is_control_insn)         // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
                     );


   //
   // REGISTER FILE INSTANTIATION
   //
   lc4_regfile #(16) regfile( .clk(clk),
                              .gwe(gwe),
                              .rst(rst),
                              .i_rs(decode_rssel),                    // rs selector
                              .o_rs_data(decode_regfile_rs_output),   // rs contents
                              .i_rt(decode_rtsel),                    // rt selector
                              .o_rt_data(decode_regfile_rt_output),   // rt contents
                              .i_rd(writeback_rdsel),                    // rd selector
                              .i_wdata(decode_regfile_rd_input) ,     // data to write
                              .i_rd_we(writeback_regfile_we)             // write enable
                            );
   //Wire Declaration
   wire [15:0] decode_pc_pipeline_out; // Output of PC Fetch pipeline register
   wire [15:0] decode_ir_pipeline_out; // Output of IR Fetch pipeline register

   wire [ 2:0] decode_rssel;              // rs
   wire        decode_rsre;               // does this instruction read from rs?
   wire [ 2:0] decode_rtsel;              // rt
   wire        decode_rtre;               // does this instruction read from rt?
   wire [ 2:0] decode_rdsel;               // rd
   wire        decode_regfile_we;         // does this instruction write to rd?
   wire        decode_nzp_we;             // does this instruction write the NZP bits?
   wire        decode_select_pc_plus_one; // write PC+1 to the regfile?
   wire        decode_is_load;            // is this a load instruction?
   wire        decode_is_store;           // is this a store instruction?
   wire        decode_is_branch;          // is this a branch instruction?
   wire        decode_is_control_insn;     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
   wire [15:0] decode_regfile_rs_output; 
   wire [15:0] decode_regfile_rt_output; 
   wire [15:0] decode_regfile_rd_input; 

   wire [15:0] execute_regfile_rs_input;
   wire [15:0] execute_regfile_rt_input;

   //
   // Logic
   //
  // assign decode_regfile_rd_input = (writeback_select_pc_plus_one == 1'b1) ? decode_pc_pipeline_out : writeback_alu_pipeline_out;

     assign decode_regfile_rd_input = (writeback_is_load == 1'b1) ? i_cur_dmem_data : 
                             (writeback_select_pc_plus_one == 1'b1)  ? decode_pc_pipeline_out : 
                                                             writeback_alu_pipeline_out;

   // assign execute_regfile_rs_input = decode_regfile_rs_output;
   // assign execute_regfile_rt_input = decode_regfile_rt_output;

   // // WD Bypass Logic
   assign execute_regfile_rs_input = ((writeback_rdsel == decode_rssel) && writeback_regfile_we) ? writeback_alu_pipeline_out : 
                                                                           decode_regfile_rs_output;
   assign execute_regfile_rt_input = ((writeback_rdsel == decode_rtsel) && writeback_regfile_we) ? writeback_alu_pipeline_out : 
                                                                          decode_regfile_rt_output;


   /*************************************************************************************
   *    EXECUTE STAGE
   *************************************************************************************/
   //==============================================================
   // REGISTER DECLARATION 
   // Registers: 
   // - Instruction Register(From Decode Stage IR)
   // - PC output from Decode stage PC Reg
   // - Output from Regfile 
   // - Output from Regfile
   //==============================================================
   // Pipeline Registers : PC
   Nbit_reg #(16, 16'h8200) execute_pc_pipeline_reg (.in(decode_pc_pipeline_out), .out(execute_pc_pipeline_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Pipeline Instruction Register
   Nbit_reg #(16, 16'h0000) execute_ir_pipeline_reg (.in(decode_ir_pipeline_out), .out(execute_ir_pipeline_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   // Pipeline Rs
   Nbit_reg #(16, 16'h0000) execute_rs_pipeline_reg (.in(execute_regfile_rs_input), .out(execute_rs_pipeline_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Pipeline Rt 
   Nbit_reg #(16, 16'h0000) execute_rt_pipeline_reg (.in(execute_regfile_rt_input), .out(execute_rt_pipeline_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   // NZP Register
   Nbit_reg #(3) nzp_reg (.in(nzp_in), .out(nzp_out), .clk(clk), .we(execute_nzp_we), .gwe(gwe), .rst(rst));


   // Rs
   Nbit_reg #(3, 3'h0) execute_rs_reg (.in(decode_rssel), .out(execute_rssel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Rs Enable
   Nbit_reg #(1, 1'h0) execute_rsre_pipeline_reg (.in(decode_rsre), .out(execute_rsre), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   // Rt
   Nbit_reg #(3, 3'h0) execute_rtsel_pipeline_reg (.in(decode_rtsel), .out(execute_rtsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Rt Enable 
   Nbit_reg #(1, 1'h0) execute_rtre_pipeline_reg (.in(decode_rtre), .out(execute_rtre), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Rd
   Nbit_reg #(3, 3'h0) execute_rdsel_pipeline_reg (.in(decode_rdsel), .out(execute_rdsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Regfile Enable
   Nbit_reg #(1, 1'h0) execute_regfile_we_pipeline_reg (.in(decode_regfile_we), .out(execute_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   // NZP write enable
   Nbit_reg #(1, 1'h0) execute_nzp_we_pipeline_reg (.in(decode_nzp_we), .out(execute_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // select_pc_plus_one? 
   Nbit_reg #(1, 1'h0) execute_select_pc_plus_one_pipeline_reg (.in(decode_select_pc_plus_one), .out(execute_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Is load?
   Nbit_reg #(1, 1'h0) execute_is_load_pipeline_reg (.in(decode_is_load), .out(execute_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Is store?
   Nbit_reg #(1, 1'h0) execute_is_store_pipeline_reg (.in(decode_is_store), .out(execute_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Is Branch?
   Nbit_reg #(1, 1'h0) execute_is_branch_pipeline_reg (.in(decode_is_branch), .out(execute_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   // Is control?
   Nbit_reg #(1, 1'h0) execute_is_control_pipeline_reg (.in(decode_is_control_insn), .out(execute_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   
   //
   // ALU INSTANTIATION
   //
   lc4_alu alu(.i_insn(execute_ir_pipeline_out),
               .i_pc(execute_pc_pipeline_out),
               .i_r1data(execute_aluin_rs),
               .i_r2data(execute_aluin_rt),
               .o_result(alu_rd_output));

   //Wire Declaration
   wire [15:0] execute_pc_pipeline_out; // Output of PC Fetch pipeline register
   wire [15:0] execute_ir_pipeline_out; // Output of IR Fetch pipeline register
   wire [15:0] execute_rs_pipeline_out; // Output of RS Fetch pipeline register
   wire [15:0] execute_rt_pipeline_out; // Output of IR Fetch pipeline register

   wire [ 2:0] execute_rssel;              // rs
   wire        execute_rsre;               // does this instruction read from rs?
   wire [ 2:0] execute_rtsel;              // rt
   wire        execute_rtre;               // does this instruction read from rt?
   wire [ 2:0] execute_rdsel;               // rd
   wire        execute_regfile_we;         // does this instruction write to rd?
   wire        execute_nzp_we;             // does this instruction write the NZP bits?
   wire        execute_select_pc_plus_one; // write PC+1 to the regfile?
   wire        execute_is_load;            // is this a load instruction?
   wire        execute_is_store;           // is this a store instruction?
   wire        execute_is_branch;          // is this a branch instruction?
   wire        execute_is_control_insn;     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?

   wire [15:0] execute_aluin_rs;
   wire [15:0] execute_aluin_rt; 

   wire [15:0] alu_rd_output;

   wire [2:0] nzp_in;
   wire[2:0] nzp_out;

   //
   // Logic
   //
   assign  nzp_in =  (alu_rd_output[15] == 1'b1) ? 3'b100 :       // N
                     (alu_rd_output == 16'b0)    ? 3'b010 :       // Z
                     (alu_rd_output[15] == 1'b0) ? 3'b001 :       // P
                                                   3'b000;

   //
   // Bypassing
   //

   // ALU IN RS Bypass Logic
   assign execute_aluin_rs = ((memory_rdsel == execute_rssel) && memory_regfile_we)    ? memory_alu_pipeline_out :     // MX
                             ((writeback_rdsel == execute_rssel) && writeback_regfile_we) ? writeback_alu_pipeline_out :  // WX
                                                                                    execute_rs_pipeline_out;
   // ALU IN RT Bypass Logic
   assign execute_aluin_rt = ((memory_rdsel == execute_rtsel) && memory_regfile_we)    ? memory_alu_pipeline_out :     // MX
                             ((writeback_rdsel == execute_rtsel) && writeback_regfile_we) ? writeback_alu_pipeline_out :  // WX
                             
                                                                                    execute_rt_pipeline_out;
   /*************************************************************************************
    *    MEMORY STAGE
    *************************************************************************************/
   //==============================================================
   // REGISTER DECLARATION 
   // Registers: 
   // - Instruction Register(From EXECUTE Stage IR)
   // - ALU output
   // - RT output from Regfile
   //==============================================================

   // Pipeline Registers : PC
   Nbit_reg #(16, 16'h8200) memory_pc_pipeline_reg (.in(execute_pc_pipeline_out), .out(memory_pc_pipeline_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Pipeline Instruction Register
   Nbit_reg #(16, 16'h0000) memory_ir_pipeline_reg (.in(execute_ir_pipeline_out), .out(memory_ir_pipeline_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   // ALU Output
   Nbit_reg #(16, 16'h0000) memory_alu_pipeline_reg (.in(alu_rd_output), .out(memory_alu_pipeline_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Pipeline Rt 
   Nbit_reg #(16, 16'h0000) memory_rt_pipeline_reg (.in(execute_rt_pipeline_out), .out(memory_rt_pipeline_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   // // Decoder
   // lc4_decoder decoder_memory( .insn(memory_ir_pipeline_out),                   // instruction input  wire [15:0] 
   //                            .r1sel(memory_rssel),                            // rs
   //                            .r1re(memory_rsre),                              // does this instruction read from rs?
   //                            .r2sel(memory_rtsel),                            // rt
   //                            .r2re(memory_rtre),                              // does this instruction read from rt?
   //                            .wsel(memory_rdsel),                             // rd
   //                            .regfile_we(memory_regfile_we),                  // does this instruction write to rd?
   //                            .nzp_we(memory_nzp_we),                          // does this instruction write the NZP bits?
   //                            .select_pc_plus_one(memory_select_pc_plus_one),  // write PC+1 to the regfile?
   //                            .is_load(memory_is_load),                        // is this a load instruction?
   //                            .is_store(memory_is_store),                      // is this a store instruction?
   //                            .is_branch(memory_is_branch),                    // is this a branch instruction?
   //                            .is_control_insn(memory_is_control_insn)         // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
   //                         );

   // Rs
   Nbit_reg #(3, 3'h0) memory_rs_reg (.in(execute_rssel), .out(memory_rssel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Rs Enable
   Nbit_reg #(1, 1'h0) memory_rsre_pipeline_reg (.in(execute_rsre), .out(memory_rsre), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   // Rt
   Nbit_reg #(3, 3'h0) memory_rtsel_pipeline_reg (.in(execute_rtsel), .out(memory_rtsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Rt Enable 
   Nbit_reg #(1, 1'h0) memory_rtre_pipeline_reg (.in(execute_rtre), .out(memory_rtre), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Rd
   Nbit_reg #(3, 3'h0) memory_rdsel_pipeline_reg (.in(execute_rdsel), .out(memory_rdsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Regfile Enable
   Nbit_reg #(1, 1'h0) memory_regfile_we_pipeline_reg (.in(execute_regfile_we), .out(memory_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   // NZP write enable
   Nbit_reg #(1, 1'h0) memory_nzp_we_pipeline_reg (.in(execute_nzp_we), .out(memory_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // select_pc_plus_one? 
   Nbit_reg #(1, 1'h0) memory_select_pc_plus_one_pipeline_reg (.in(execute_select_pc_plus_one), .out(memory_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Is load?
   Nbit_reg #(1, 1'h0) memory_is_load_pipeline_reg (.in(execute_is_load), .out(memory_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Is store?
   Nbit_reg #(1, 1'h0) memory_is_store_pipeline_reg (.in(execute_is_store), .out(memory_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Is Branch?
   Nbit_reg #(1, 1'h0) memory_is_branch_pipeline_reg (.in(execute_is_branch), .out(memory_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   // Is control?
   Nbit_reg #(1, 1'h0) memory_is_control_pipeline_reg (.in(execute_is_control_insn), .out(memory_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   //
   // Wires
   //
   wire [15:0] memory_ir_pipeline_out;
   wire [15:0] memory_alu_pipeline_out;
   wire [15:0] memory_rt_pipeline_out;
   wire [15:0] memory_pc_pipeline_out;
   wire [15:0] mem_write_bypass_to_data;

   wire [ 2:0] memory_rssel;              // rs
   wire        memory_rsre;               // does this instruction read from rs?
   wire [ 2:0] memory_rtsel;              // rt
   wire        memory_rtre;               // does this instruction read from rt?
   wire [ 2:0] memory_rdsel;               // rd
   wire        memory_regfile_we;         // does this instruction write to rd?
   wire        memory_nzp_we;             // does this instruction write the NZP bits?
   wire        memory_select_pc_plus_one; // write PC+1 to the regfile?
   wire        memory_is_load;            // is this a load instruction?
   wire        memory_is_store;           // is this a store instruction?
   wire        memory_is_branch;          // is this a branch instruction?
   wire        memory_is_control_insn;     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?

   //
   // Logic 
   //

   assign o_dmem_towrite = (memory_is_store == 1'b1) ? mem_write_bypass_to_data : 16'h0000;
   assign o_dmem_we = memory_is_store; 

   assign o_dmem_addr = (memory_is_store == 1'b1 || 
                          memory_is_load == 1'b1) ? memory_alu_pipeline_out : 
                                                    16'h0000;

   assign test_dmem_we             = memory_is_store;       // Testbench: data memory write enable
   assign test_dmem_addr           = o_dmem_addr;     // Testbench: address to read/write memory
   assign test_dmem_data           = (memory_is_store == 1'b1) ? o_dmem_towrite :
                                      (memory_is_load  == 1'b1) ? i_cur_dmem_data : 16'h0000;



   // WM BYPASSING
   // =============

   assign mem_write_bypass_to_data = ((writeback_rdsel == memory_rtsel) && memory_is_store) ? decode_regfile_rd_input :     // WM
                                                                                              memory_rt_pipeline_out;

   /************************************************************************************
    *    WRITE-BACK STAGE
    *************************************************************************************/
   //
   // REGISTER DECLARATION 
   // Registers: 
   // - Instruction Register(From EXECUTE Stage IR)
   // - ALU output
   // - Output from Memory
   //==============================================================

   // Pipeline Registers : PC
   Nbit_reg #(16, 16'h8200) writeback_pc_pipeline_reg (.in(memory_pc_pipeline_out), .out(writeback_pc_pipeline_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Pipeline Instruction Register
   Nbit_reg #(16, 16'h0000) writeback_ir_pipeline_reg (.in(memory_ir_pipeline_out), .out(writeback_ir_pipeline_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   // Data Memory Output
   Nbit_reg #(16, 16'h0000) writeback_data_pipeline_reg (.in(i_cur_dmem_data), .out(writeback_data_pipeline_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Pipeline Rt 
   Nbit_reg #(16, 16'h0000) writeback_alu_pipeline_reg (.in(memory_alu_pipeline_out), .out(writeback_alu_pipeline_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   // // Decoder
   // lc4_decoder decoder_writeback( .insn(writeback_ir_pipeline_out),                   // instruction input  wire [15:0] 
   //                            .r1sel(writeback_rssel),                            // rs
   //                            .r1re(writeback_rsre),                              // does this instruction read from rs?
   //                            .r2sel(writeback_rtsel),                            // rt
   //                            .r2re(writeback_rtre),                              // does this instruction read from rt?
   //                            .wsel(writeback_rdsel),                             // rd
   //                            .regfile_we(writeback_regfile_we),                  // does this instruction write to rd?
   //                            .nzp_we(writeback_nzp_we),                          // does this instruction write the NZP bits?
   //                            .select_pc_plus_one(writeback_select_pc_plus_one),  // write PC+1 to the regfile?
   //                            .is_load(writeback_is_load),                        // is this a load instruction?
   //                            .is_store(writeback_is_store),                      // is this a store instruction?
   //                            .is_branch(writeback_is_branch),                    // is this a branch instruction?
   //                            .is_control_insn(writeback_is_control_insn)         // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
   //                         );

   // Rs
   Nbit_reg #(3, 3'h0) writeback_rs_reg (.in(memory_rssel), .out(writeback_rssel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Rs Enable
   Nbit_reg #(1, 1'h0) writeback_rsre_pipeline_reg (.in(memory_rsre), .out(writeback_rsre), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   // Rt
   Nbit_reg #(3, 3'h0) writeback_rtsel_pipeline_reg (.in(memory_rtsel), .out(writeback_rtsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Rt Enable 
   Nbit_reg #(1, 1'h0) writeback_rtre_pipeline_reg (.in(memory_rtre), .out(writeback_rtre), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Rd
   Nbit_reg #(3, 3'h0) writeback_rdsel_pipeline_reg (.in(memory_rdsel), .out(writeback_rdsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Regfile Enable
   Nbit_reg #(1, 1'h0) writeback_regfile_we_pipeline_reg (.in(memory_regfile_we), .out(writeback_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   // NZP write enable
   Nbit_reg #(1, 1'h0) writeback_nzp_we_pipeline_reg (.in(memory_nzp_we), .out(writeback_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // select_pc_plus_one? 
   Nbit_reg #(1, 1'h0) writeback_select_pc_plus_one_pipeline_reg (.in(memory_select_pc_plus_one), .out(writeback_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Is load?
   Nbit_reg #(1, 1'h0) writeback_is_load_pipeline_reg (.in(memory_is_load), .out(writeback_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Is store?
   Nbit_reg #(1, 1'h0) writeback_is_store_pipeline_reg (.in(memory_is_store), .out(memory_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Is Branch?
   Nbit_reg #(1, 1'h0) writeback_is_branch_pipeline_reg (.in(memory_is_branch), .out(memory_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
   // Is control?
   Nbit_reg #(1, 1'h0) writeback_is_control_pipeline_reg (.in(memory_is_control_insn), .out(memory_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   //
   // Wire Declarations
   //
   wire [15:0] writeback_alu_pipeline_out;
   wire [15:0] writeback_data_pipeline_out;
   wire [15:0] writeback_ir_pipeline_out;
   wire [15:0] writeback_pc_pipeline_out;

   wire [ 2:0] writeback_rssel;              // rs
   wire        writeback_rsre;               // does this instruction read from rs?
   wire [ 2:0] writeback_rtsel;              // rt
   wire        writeback_rtre;               // does this instruction read from rt?
   wire [ 2:0] writeback_rdsel;               // rd
   wire        writeback_regfile_we;         // does this instruction write to rd?
   wire        writeback_nzp_we;             // does this instruction write the NZP bits?
   wire        writeback_select_pc_plus_one; // write PC+1 to the regfile?
   wire        writeback_is_load;            // is this a load instruction?
   wire        writeback_is_store;           // is this a store instruction?
   wire        writeback_is_branch;          // is this a branch instruction?
   wire        writeback_is_control_insn;     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?


   //========================================================
   // TEST SIGNALS
   //=======================================================
   
    assign test_stall = (writeback_ir_pipeline_out[15:9] == 7'b0) ? 2'b10 : 2'b00; // No Stall
    //assign test_stall = 2'b0; 
    assign test_cur_pc =  writeback_pc_pipeline_out;// Testbench: program counter
    assign test_cur_insn = writeback_ir_pipeline_out; // Testbench: instruction bits
    assign test_regfile_we = writeback_regfile_we; // Testbench: register file write enable
    assign test_regfile_wsel = writeback_rdsel; // Testbench: which register to write in the register file 
    assign test_regfile_data = writeback_alu_pipeline_out; // Testbench: value to write into the register file
    assign test_nzp_we = writeback_nzp_we; // Testbench: NZP condition codes write enable
    assign test_nzp_new_bits = (writeback_alu_pipeline_out[15] == 1'b1) ? 3'b100 :       // N
                               (writeback_alu_pipeline_out == 16'b0)    ? 3'b010 :       // Z
                               (writeback_alu_pipeline_out[15] == 1'b0) ? 3'b001 :       // P
                                                             3'b000; // Testbench: value to write to NZP bits




// ----------------------
// STALL CODE
// ----------------------



// -------------------------










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
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      //$display(); 
   end
`endif
endmodule