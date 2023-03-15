echo \`define INPUT_FILE \"/mnt/castor/seas_home/s/shantz/cis5710/CIS5710_Shantykins/lab3-singlecycle/test_data/test_alu.ctrace\" > .set_testcase.v
echo \`define OUTPUT_FILE \"/mnt/castor/seas_home/s/shantz/cis5710/CIS5710_Shantykins/lab3-singlecycle/test_data/test_alu.output\" >> .set_testcase.v
echo \`define ORIG_INPUT_FILE \"/mnt/castor/seas_home/s/shantz/cis5710/CIS5710_Shantykins/lab3-singlecycle/test_data/test_alu.trace\" >> .set_testcase.v
echo \`define MEMORY_IMAGE_FILE \"/mnt/castor/seas_home/s/shantz/cis5710/CIS5710_Shantykins/lab3-singlecycle/test_data/test_alu.hex\" >> .set_testcase.v
echo \`define TEST_CASE \"test_alu\" >> .set_testcase.v
echo \`define VCD_FILE \"test_alu.vcd\" >> .set_testcase.v
Writing check output to check.log...
/home1/c/cis5710/tools/yosys -p "check; hierarchy -check; flatten; check -assert" .set_testcase.v lc4_alu.v lc4_cla.v lc4_decoder.v lc4_divider.v lc4_regfile.v lc4_single.v include/register.v include/lc4_memory.v include/clock_util.v include/delay_eight_cycles.v include/bram.v | tee check.log

 /----------------------------------------------------------------------------\
 |                                                                            |
 |  yosys -- Yosys Open SYnthesis Suite                                       |
 |                                                                            |
 |  Copyright (C) 2012 - 2020  Claire Wolf <claire@symbioticeda.com>          |
 |                                                                            |
 |  Permission to use, copy, modify, and/or distribute this software for any  |
 |  purpose with or without fee is hereby granted, provided that the above    |
 |  copyright notice and this permission notice appear in all copies.         |
 |                                                                            |
 |  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES  |
 |  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF          |
 |  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR   |
 |  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES    |
 |  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN     |
 |  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF   |
 |  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.            |
 |                                                                            |
 \----------------------------------------------------------------------------/

 Yosys 0.9+3855 (git sha1 54294957, clang 7.0.1 -fPIC -Os)


-- Parsing `.set_testcase.v' using frontend `verilog' --

1. Executing Verilog-2005 frontend: .set_testcase.v
Parsing Verilog input from `.set_testcase.v' to AST representation.
Successfully finished Verilog frontend.

-- Parsing `lc4_alu.v' using frontend `verilog' --

2. Executing Verilog-2005 frontend: lc4_alu.v
Parsing Verilog input from `lc4_alu.v' to AST representation.
Generating RTLIL representation for module `\lc4_alu'.
Successfully finished Verilog frontend.

-- Parsing `lc4_cla.v' using frontend `verilog' --

3. Executing Verilog-2005 frontend: lc4_cla.v
Parsing Verilog input from `lc4_cla.v' to AST representation.
Generating RTLIL representation for module `\gp1'.
Generating RTLIL representation for module `\gp4'.
Generating RTLIL representation for module `\cla16'.
Generating RTLIL representation for module `\gpn'.
Successfully finished Verilog frontend.

-- Parsing `lc4_decoder.v' using frontend `verilog' --

4. Executing Verilog-2005 frontend: lc4_decoder.v
Parsing Verilog input from `lc4_decoder.v' to AST representation.
Generating RTLIL representation for module `\lc4_decoder'.
Successfully finished Verilog frontend.

-- Parsing `lc4_divider.v' using frontend `verilog' --

5. Executing Verilog-2005 frontend: lc4_divider.v
Parsing Verilog input from `lc4_divider.v' to AST representation.
Generating RTLIL representation for module `\lc4_divider'.
Generating RTLIL representation for module `\lc4_divider_one_iter'.
Successfully finished Verilog frontend.

-- Parsing `lc4_regfile.v' using frontend `verilog' --

6. Executing Verilog-2005 frontend: lc4_regfile.v
Parsing Verilog input from `lc4_regfile.v' to AST representation.
Generating RTLIL representation for module `\lc4_regfile'.
Generating RTLIL representation for module `\Nbit_mux8to1'.
Generating RTLIL representation for module `\decoder_3_to_8'.
Successfully finished Verilog frontend.

-- Parsing `lc4_single.v' using frontend `verilog' --

7. Executing Verilog-2005 frontend: lc4_single.v
