// $Id: $mg97
// File name:   raid_top.sv
// Created:     11/30/2015
// Author:      Renjun Zheng
// Lab Section: 337-007
// Version:     1.0  Initial Design Entry
// Description: RAID top level

`timescale 1ns/10ps

module raid_top(
	input wire clk,
	input wire n_rst,

	//ahb
	input wire h_ready, hwrite,
	output wire ahb_done, //send back to ahb

	output wire [31:0] cache_ahb_out_data_seleted,
	input wire [31:0] ahb_address,
	input wire [31:0] ahb_cache_in_data,

	//sd
	output wire sd_mode,
	output wire sd_start,
	output wire [31:0] sd_block_no,
        output wire sd_load_enable,


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
	output wire [6:0] cache_offset,

	input wire        exists,
	input wire        full,
	input wire [31:0] cache_out,
	input wire [31:0] cache_in_block_no,
	input wire [6:0] cache_in_offset,	

	//sram 
	output wire r_enable_sram1, r_eanble_sram2, w_enable_sram1, w_enable_sram2, // didn't connect with any ports
	input wire [31:0] r_data_sram1, r_data_sram2,
	output wire [31:0] w_data_sram1, w_data_sram2, address_sram1, address_sram2,
	output wire [31:0] cache_ahb_out_data
);

	reg mode;
	reg [5:0] sd_error;
	reg sram_counter_rollover_flag;
	reg valid;
	reg cache_counter_rollover_flag;
	reg [2:0] op_code;
	reg [7:0] cache_counter_count_out;
	reg [7:0] cache_counter_rollover_val;
	reg sram_data_sd_or_cache;
	reg cache_counter_enable;
	reg sram1_import_enable;
	reg sram2_import_enable;
	reg sram_counter_clear;
	reg sram1_export_enable;
	reg sram2_export_enable;
	reg sram_counter_count_enable;
	
	reg cache_counter_clear;
	reg [6:0] sram_counter_count_out;
	reg [8:0] status;
	reg [31:0] parity;

	reg [1:0] sram1sd;
	reg [1:0] sram2sd;
	reg [31:0] ahb_block_no;
	reg [6:0] ahb_offset;
	reg ahb_start;

	reg [6:0] ahb_length;

	reg [2:0] cache_in_data_select;
	reg [1:0] cache_out_data_select;

	reg [31:0] sram1_sd_data;
	reg [31:0] sram2_sd_data;

	reg[31:0] sram1_cache_data;
	reg[31:0] sram2_cache_data;

	reg block_no_counter_enable;
	reg block_no_counter_rollover_flag;
	reg [10:0] block_no_counter_count_out;
	reg [1:0] block_calculator_mode;
	reg [1:0] block_calculator_sd_no;

	reg[31:0] cache_sram1_data;
	reg[31:0] cache_sram2_data;
	reg req, config_ready, sram1_clear, sram2_clear;
	
	reg [31:0] blk_addC_out;
	reg[1:0] block_calculator_sram1_sd_no;

	reg [1:0] addC_sd_sram1, addC_sd_sram2;
	reg [31:0] sram_true_offset;
	reg [31:0] statereg;


	reg [31:0] sd_sram1_data;
	reg [31:0] sd_sram2_data;

	reg sram_info_set;

	reg sd_write_enable;
	reg sd_read_enable;

	assign sd_load_enable = sd_write_enable | sd_read_enable;

	reg block_no_counter_clear;
	reg sram_offset_select;



	configcontroller configcontroller(
		.clk(clk),
		.n_rst(n_rst),
		.instruction(ahb_address),
		.w_data(ahb_cache_in_data),
		.mode_in(hwrite),
		.ahb_ready(h_ready),
		.block_num(ahb_block_no),
		.length(ahb_length),
		.offset(ahb_offset),
		.special(op_code),
		.req(req),
		.ready_out(config_ready),
		.enable(ahb_start),
		.mode_out(mode)
		);

	addCalculator addCalculator(.blk_ca(cache_in_block_no),
		.blk_ahb(ahb_block_no),
		.blk_count(block_no_counter_count_out),
		.mode(block_calculator_mode),
		.sd_in(block_calculator_sd_no),
		.sd_out_sram1(addC_sd_sram1),
		.sd_out_sram2(addC_sd_sram2),
		.blk_out(blk_addC_out)
		);
			
	sramController sramController1(.clk(clk),
					.n_rst(n_rst),
					.sd(addC_sd_sram1),
					.blkno(blk_addC_out),
					.data_ca_in(cache_sram1_data),
					.offset(sram_true_offset),
					.sdorca(sram_data_sd_or_cache),
					.r_enable(sram1_export_enable),
					.w_enable(sram1_import_enable),
					.r_data_sram(r_data_sram1),
					.w_data_sram(w_data_sram1),
					.data_sd_in(sram1sd),
					.clrsignal(sram1_clear),
					.data_sd_out(sram1_sd_data),
					.blkno_out(sd_block_no),
					.data_ca_out(sram1_cache_data),
					.sd_out(sram1sd),
					.address_sram(address_sram1)
					);
	
	sramController sramController2(.clk(clk),
					.n_rst(n_rst),
					.sd(addC_sd_sram2),
					.blkno(blk_addC_out),
					.data_ca_in(cache_sram2_data),
					.offset(sram_true_offset),
					.sdorca(sram_data_sd_or_cache),
					.r_enable(sram2_export_enable),
					.w_enable(sram2_import_enable),
					.r_data_sram(r_data_sram2),
					.w_data_sram(w_data_sram2),
					.data_sd_in(sram2sd),
					.clrsignal(sram2_clear),
					.data_sd_out(sram2_sd_data),
					.blkno_out(sd_block_no),
					.data_ca_out(sram2_cache_data),
					.sd_out(sram2sd),
					.address_sram(address_sram2)
					);

	data_select_toahb data_select_toahb(.clk(clk),
						.n_rst(n_rst),
						.statereg(status),
						.cachedata(cache_ahb_out_data),
						.instruction(ahb_address),
						.h_ready(h_ready),
						.data_out(cache_ahb_out_data_seleted)
					);

	control_unit control_unit(
		.clk(clk),
		.n_rst(n_rst),
		.ahb_ready(config_ready),

		.mode(mode),
		.exists(exists),
		.full(full),
		.sd_ready(sd_ready),
		.sd_error(sd_error),
		.sram_counter_rollover_flag(sram_counter_rollover_flag),
		.valid(valid),
		.cache_counter_rollover_flag(cache_counter_rollover_flag),
		.op_code(op_code),
		.cache_counter_count_out(cache_counter_count_out),

		.cache_offset(cache_offset),
		.cache_counter_rollover_val(cache_counter_rollover_val),
		.sram_data_sd_or_cache(sram_data_sd_or_cache),
		.cache_counter_enable(cache_counter_enable),
		.sram1_import_enable(sram1_import_enable),
		.sram2_import_enable(sram2_import_enable),
		.sd_start(sd_start),
		.sd_mode(sd_mode),
		.sram_counter_clear(sram_counter_clear),
		.sd_write_enable(sd_write_enable),
		.sram1_export_enable(sram1_export_enable),
		.sram2_export_enable(sram2_export_enable),
		.sram_counter_count_enable(sram_counter_count_enable),
		.cache_mode(cache_mode),
		.sd_read_enable(sd_read_enable),
		.cache_block_no(cache_block_no),
		.cache_counter_clear(cache_counter_clear),

		.ahb_block_no(ahb_block_no),
		.ahb_offset(ahb_offset),
		.ahb_start(ahb_start),
		.ahb_done(ahb_done),
		.ahb_length(ahb_length),

		.cache_in_data_select(cache_in_data_select),
		.cache_out_data_select(cache_out_data_select),
		.status(status),

		.block_no_counter_rollover_flag(block_no_counter_rollover_flag),
		.block_no_counter_enable(block_no_counter_enable),
		.block_no_counter_clear(block_no_counter_clear),
		.block_calculator_mode(block_calculator_mode),
		.block_calculator_sd_no(block_calculator_sd_no),

		.sram_counter_count_out(sram_counter_count_out),
		.sram1_clear(sram1_clear),
		.sram2_clear(sram2_clear),
		.block_calculator_sram1_sd_no(addC_sd_sram1),
		.sram_info_set(sram_info_set),
		.sram_offset_select(sram_offset_select)
	);
	
	cache_counter cache_counter(
		.clk(clk),
		.n_rst(n_rst),
		.cnt_enable(cache_counter_enable),
		.clear(cache_counter_clear),
		.rollover_val(cache_counter_rollover_val),
		.count_out(cache_counter_count_out),
		.rollover_flag(cache_counter_rollover_flag)
	);

	sram_counter sram_counter(
		.clk(clk),
		.n_rst(n_rst),
		.cnt_enable(sram_counter_count_enable),
		.clear(sram_counter_clear),
		.rollover_flag(sram_counter_rollover_flag),
		.count_out(sram_counter_count_out)
	);
	
	parity_gen parity_gen(
		.block1(sram1_sd_data),
		.block2(sram2_sd_data),
		.result(parity)
	);
	

	sd_data_in_select select1(
		.selectid(2'd1),
		.sram1(sram1_sd_data),
		.sram2(sram2_sd_data),
		.parity(parity),
		.sram1sd(sram1sd),
		.sram2sd(sram2sd),
		.result(sd1in)
	);

	sd_data_in_select select2(
		.selectid(2'd2),
		.sram1(sram1_sd_data),
		.sram2(sram2_sd_data),
		.parity(parity),
		.sram1sd(sram1sd),
		.sram2sd(sram2sd),
		.result(sd2in)
	);

	sd_data_in_select select3(
		.selectid(2'd3),
		.sram1(sram1_sd_data),
		.sram2(sram2_sd_data),
		.parity(parity),
		.sram1sd(sram1sd),
		.sram2sd(sram2sd),
		.result(sd3in)
	);

	sd_data_out_select sram1select(
		.sd1_data(sd1out),
		.sd2_data(sd2out),
		.sd3_data(sd3out),
		.selectid(2'd1),
		.sram1sd(sram1sd),
		.sram2sd(sram2sd),
		.output_data(sd_sram1_data)
	);

	sd_data_out_select sram2select(
		.sd1_data(sd1out),
		.sd2_data(sd2out),
		.sd3_data(sd3out),
		.selectid(2'd2),
		.sram1sd(sram1sd),
		.sram2sd(sram2sd),
		.output_data(sd_sram2_data)
	);

	parity_checker parity_checker(
		.input1(sd1out),
		.input2(sd2out),
		.input3(sd3out),
		.valid(valid)
	);

	
	cache_data_in_mux cache_in_selector(
		.ahb_data(ahb_cache_in_data),
		.sram1_data(sram1_cache_data),
		.sram2_data(sram2_cache_data),
		.sd1_data(sd1out),
		.sd2_data(sd2out),
		.sd3_data(sd3out),
		.select_out(cache_in_data_select),
		.output_data(cache_in)
	);
	
	cache_data_out_mux cache_out_selector(
		.input_data(cache_out),
		.select_out(cache_out_data_select),
		.ahb_data(cache_ahb_out_data),
		.sram1_data(cache_sram1_data),
		.sram2_data(cache_sram2_data)
	);

	sd_error_combine error_combine(
		.sd1_error(sd1_error),
		.sd3_error(sd2_error),
		.sd2_error(sd3_error),
		.sd_error(sd_error)
	);

	block_no_counter block_no_counter(
		.clk(clk),
		.n_rst(n_rst),
		.cnt_enable(block_no_counter_enable),
		.clear(block_no_counter_clear),
		.rollover_flag(block_no_counter_rollover_flag),
		.count_out(block_no_counter_count_out)
	);

	sram_offset_mux sram_offset_mux(
		.cache_out_offset(cache_in_offset),
		.sram_counter_count_out(sram_counter_count_out),
		.select(sram_offset_select),
		.sram_offset(sram_true_offset)
	);
endmodule
