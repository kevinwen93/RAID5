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




	localparam TB_ADDR_SIZE_BITS	= 16; 	// 16 => 64K Words in Memory
	localparam TB_DATA_SIZE_WORDS	= 1;		// Single word access (only a demo case, can access arbitraliy many bytes during an access but all accesses must be the number of words wide)
	localparam TB_WORD_SIZE_BYTES	= 1;		// Single byte words (only a demo case, words can be as large as 3 bytes)
	localparam TB_ACCES_SIZE_BITS	= (TB_DATA_SIZE_WORDS * TB_WORD_SIZE_BYTES * 8);
	
	// Useful test bench constants
	localparam TB_CAPACITY_WORDS	= (2 ** TB_ADDR_SIZE_BITS);
	localparam TB_MAX_ADDRESS			= (TB_CAPACITY_WORDS - 1);
	localparam TB_WORD_SIZE_BITS	= (TB_WORD_SIZE_BYTES * 8);
	localparam TB_MAX_WORD_BIT		= (TB_WORD_SIZE_BITS - 1);
	localparam TB_ACC_SIZE_BITS		= (TB_WORD_SIZE_BITS * TB_DATA_SIZE_WORDS);
	localparam TB_MAX_ACC_BIT			= (TB_ACC_SIZE_BITS - 1);
	
	localparam TB_MAX_WORD	= ((2 ** (TB_WORD_SIZE_BYTES * 8)) - 1);
	localparam TB_ZERO_WORD	= 0;
	localparam TB_MAX_ACC		= ((2 ** TB_ACCES_SIZE_BITS) - 1);
	localparam TB_ZERO_ACC	= 0;
	
	// Test bench variables
	integer unsigned tb_init_file_number;	// Can't be larger than a value of (2^31 - 1) due to how VHDL stores unsigned ints/natural data types
	integer unsigned tb_dump_file_number;	// Can't be larger than a value of (2^31 - 1) due to how VHDL stores unsigned ints/natural data types
	integer unsigned tb_start_address;	// The first address to start dumping memory contents from
	integer unsigned tb_last_address;		// The last address to dump memory contents from
	
	reg tb_mem_clr;		// Active high strobe for at least 1 simulation timestep to zero memory contents
	reg tb_mem_init;	// Active high strobe for at least 1 simulation timestep to set the values for address in
										// currently selected init file to their corresonding values prescribed in the file
	reg tb_mem_dump;	// Active high strobe for at least 1 simulation timestep to dump all values modified since most recent mem_clr activation to
										// the currently chosen dump file. 
										// Only the locations between the "tb_start_address" and "tb_last_address" (inclusive) will be dumped
	//reg tb_verbose;		// Active high enable for more verbose debuging information
	

	
	reg [(TB_ADDR_SIZE_BITS - 1):0]		tb_address; 		// The address of the first word in the access
	reg [(TB_ACCES_SIZE_BITS - 1):0]	tb_read_data;		// The data read from the SRAM
	reg [(TB_ACCES_SIZE_BITS - 1):0]	tb_write_data;	

	
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

	reg [31:0] sd1out= 32'h66666666;
	reg [31:0] sd2out = 32'hFFFFFFFF;
	reg [31:0] sd3out  = 32'h99999999;;


	reg [31:0] ahb_block_no = 32'hABCDEFAB;
	reg [6:0] ahb_offset = 7'd2;
	reg ahb_start;
	reg ahb_done;
	reg [6:0] ahb_length = 7'd123;

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

	reg [31:0] cache_ahb_out_data;
	// Clock gen block
	always
	begin : CLK_GEN
		tb_clk = 1'b0;
		#(CLK_PERIOD / 2.0);
		tb_clk = 1'b1;
		#(CLK_PERIOD / 2.0);
	end
	
	//  portmap


	control_unit control_unit(
		.clk(tb_clk),
		.n_rst(tb_n_rst),
		.ahb_ready(h_ready),

		.mode(mode),
		.exists(exists),
		.full(full),
		.cache_dump_half(cache_dump_half),
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
		.sram1_clear(),
		.sram2_clear(),
		.block_calculator_sram1_sd_no()
	);
	
	cache_counter cache_counter(
		.clk(tb_clk),
		.n_rst(tb_n_rst),
		.cnt_enable(cache_counter_enable),
		.clear(cache_counter_clear),
		.rollover_val(cache_counter_rollover_val),
		.count_out(cache_counter_count_out),
		.cache_dump_half(cache_dump_half),
		.rollover_flag(cache_counter_rollover_flag)
	);

	sram_counter sram_counter(
		.clk(tb_clk),
		.n_rst(tb_n_rst),
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

	parity_checker parity_checker(
		.input1(sd1out),
		.input2(sd2out),
		.input3(sd3out),
		.valid(valid)
	);

	
	cache_data_in_mux cache_in_selector(
		.ahb_data(ahb_cache_data),
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
		.clk(tb_clk),
		.n_rst(tb_n_rst),
		.cnt_enable(block_no_counter_enable),
		.clear(clear),
		.rollover_flag(block_no_counter_rollover_flag),
		.count_out(block_no_counter_count_out)
	);

	on_chip_sram_wrapper on_chip_sram_wrapper(
		// Test bench control signals
		.mem_clr(tb_mem_clr),
		.mem_init(tb_mem_init),
		.mem_dump(tb_mem_dump),
		.verbose(1'b0),
		.init_file_number(tb_init_file_number),
		.dump_file_number(tb_dump_file_number),
		.start_address(tb_start_address),
		.last_address(tb_last_address),
		// Memory interface signals
		.read_enable(tb_r_enable_out),
		.write_enable(tb_w_enable_out),
		.address(tb_address_sram),
		.read_data(tb_r_data_sram),
		.write_data(tb_w_data_sram)
	);

	integer lc;

	initial begin
		@(negedge tb_clk)
		tb_n_rst = 0;
		sd1_error = 2'b0;
		sd2_error = 2'b0;
		sd3_error = 2'b0;

/*

	correct state for read cache*/
		@(negedge tb_clk)
 		tb_n_rst = 1;
 		h_ready = 1'b1;
		op_code = 3'd0;
 
 		#(CLK_PERIOD)
 		@(negedge tb_clk)
		exists = 1'b0;
 		full = 1'b1;
 		mode = 1'b1;
 		sd_ready = 1'b1;
 		ahb_start = 1'b1;

		#(CLK_PERIOD)
		@(negedge tb_clk)
		for(lc = 0; lc < 256; lc = lc + 1)
		begin
			@(negedge tb_clk);
			cache_out = lc+20;
		end



/*
		@(negedge tb_clk)
 		tb_n_rst = 1;
 		h_ready = 1'b1;
		op_code = 3'd0;
*/














		/*
		sd1out = 32'h29882167;
		sd2out = 32'h47365155;
		sd3out = 32'h72513568;*/
/*
		@(negedge tb_clk)
		tb_n_rst = 1;
		h_ready = 1'b1;
		op_code = 3'd0;


		h_ready = 1'b0;*/
		/*
		for(lc = 0; lc < 20; lc = lc + 1)
		begin
			@(negedge tb_clk);
			sd1out = 32'h000000
		end
		*/
	end
endmodule
