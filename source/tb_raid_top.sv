// $Id: $mg97
// File name:   tb_control_unit.sv
// Created:     11/30/2015
// Author:      Renjun Zheng
// Lab Section: 337-007
// Version:     1.0  Initial Design Entry
// Description: create testbench for all
`timescale 1ns/10ps

module tb_control_unit();

	// Define local constants
	localparam NUM_VAL_BITS	= 16;
	localparam MAX_VAL_BIT	= NUM_VAL_BITS - 1;
	localparam CHECK_DELAY	= 1ns;
	localparam CLK_PERIOD		= 10ns;
	
	// Define our custom test vector type
	typedef struct
	{
		reg [MAX_VAL_BIT:0] coeffs[3:0];
		reg [MAX_VAL_BIT:0] samples[3:0];
		reg [MAX_VAL_BIT:0] results[3:0];
		reg errors[3:0];
	} testVector;
	
	// Test bench dut port signals
	reg tb_clk;
	reg tb_n_rst;
	reg h_ready;
	

	reg mode; // mode = 1 is read	
	reg exists;
	reg full;
	reg cache_dump_half;
	reg sd_ready;
	reg [5:0] sd_error;
	reg sram_counter_rollover_flag;
	reg valid;
	reg cache_counter_rollover_flag;
	reg [2:0] op_code;
	reg [7:0] cache_counter_count_out;


	reg [6:0] cache_offset;
	reg [7:0] cache_counter_rollover_val;
	reg sram_data_sd_or_cache;
	reg cache_counter_enable;
	reg sram1_import_enable;
	reg sram2_import_enable;
	reg sd_start;
	reg sd_mode;
	reg sram_counter_clear;
	reg sd_write_enable;
	reg sram1_export_enable;
	reg sram2_export_enable;
	reg sram_counter_count_enable;
	reg [2:0] cache_mode;
	reg sd_read_enable;
	reg [31:0] cache_block_no;
	reg cache_counter_clear;
	
	reg [6:0] sram_counter_count_out;
	reg [8:0] status;

	reg [31:0] sram1_sd_data = 32'hFFFFFFFF;
	reg [31:0] sram2_sd_data = 32'h77777777;
	reg [31:0] parity;
	reg [1:0] sram1sd = 2'd2;
	reg [1:0] sram2sd = 2'd3;
	reg [31:0] sd1in;
	reg [31:0] sd2in;
	reg [31:0] sd3in;

	reg [31:0] sd1out = 32'h66666666;
	reg [31:0] sd2out = 32'hFFFFFFFF;
	reg [31:0] sd3out = 32'h99999999;


	reg [31:0] ahb_block_no = 32'hABCDEFAB;
	reg [6:0] ahb_offset = 7'd2;
	reg ahb_start;
	reg ahb_done;
	reg [6:0] ahb_length = 7'd10;

	reg [2:0] cache_in_data_select;
	reg [1:0] cache_out_data_select;



	reg[31:0] sram1_cache_data;
	reg[31:0] sram2_cache_data;
	reg[31:0] ahb_cache_data;
	reg[31:0] cache_in;


	reg[31:0] cache_sram1_data;
	reg[31:0] cache_sram2_data;
	reg[31:0] cache_ahb_data;
	reg[31:0] cache_out;

	reg[1:0] sd1_error;
	reg[1:0] sd2_error;
	reg[1:0] sd3_error;

	reg block_no_counter_enable;
	reg block_no_counter_rollover_flag;
	reg [10:0] block_no_counter_count_out;
	reg [1:0] block_calculator_mode;
	reg [1:0] block_calculator_sd_no;


	// Clock gen block
	always
	begin : CLK_GEN
		tb_clk = 1'b0;
		#(CLK_PERIOD / 2.0);
		tb_clk = 1'b1;
		#(CLK_PERIOD / 2.0);
	end
	
	//  portmap
	raid_top raid(
		.clk(tb_clk),
		.n_rst(tb_n_rst),

		//ahb
		input wire h_ready,
		output wire ahb_done, //send back to ahb

		output wire [31:0] cache_ahb_out_data,
		input wire [31:0] ahb_address,
		input wire [31:0] ahb_cache_in_data,

		//sd
		output wire sd_mode,
		output wire sd_start,
		output wire [31:0] sd_block_no,
		output wire sd_write_enable,
		output wire sd_read_enable,

		input wire[1:0] sd1_error, //sd send error to raid
		input wire[1:0] sd2_error,
		input wire[1:0] sd3_error,

		output wire [31:0] sd1in, //data goes to sd card
		output wire [31:0] sd2in,
		output wire [31:0] sd3in,

		input wire [31:0] sd1out,// = 32'h66666666, data goes to raid
		input wire [31:0] sd2out,// = 32'hFFFFFFFF,
		input wire [31:0] sd3out,// = 32'h99999999,

		input wire sd_ready,

		//cache
		output wire [2:0] cache_mode,
		output wire [31:0] cache_in,
		output wire [31:0] cache_block_no,
		output wire [7:0] cache_offset,

		input wire        exists,
		input wire        full,
		input wire [31:0] cache_out
	);



	initial begin
		@(negedge tb_clk)
		tb_n_rst = 0;
		sd1_error = 2'b0;
		sd2_error = 2'b0;
		sd3_error = 2'b0;
		
		@(negedge tb_clk)
		tb_n_rst = 1;
		h_ready = 1'b1;
		op_code = 3'd0;

		#(CLK_PERIOD)
		@(negedge tb_clk)
		h_ready = 1'b0;
		exists = 1'b0;
		full = 1'b1;
		mode = 1'b1;
		sd_ready = 1'b1;
		

		ahb_start = 1'b1;
	end
endmodule
