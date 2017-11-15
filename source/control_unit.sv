// $Id: $mg97
// File name:   control_unit.sv
// Created:     11/23/2015
// Author:      Renjun Zheng
// Lab Section: 337-007
// Version:     1.0  Initial Design Entry
// Description: 

module control_unit(
		    input wire 	      clk, n_rst,
		    input wire 	      ahb_ready,
		    input wire [31:0] ahb_block_no,

		    input wire 	      mode, // mode = 1 is read	
		    input wire 	      exists,
		    input wire 	      full,
		    //input wire 	      cache_dump_half,
		    input wire 	      sd_ready,
		    input wire [5:0]  sd_error,
		    input wire 	      valid,

		    input wire 	      cache_counter_rollover_flag,

		    input wire [6:0]  ahb_length,
		    input wire [7:0]  cache_counter_count_out,
		    input wire [6:0]  ahb_offset,
		    input wire 	      ahb_start,
		    input wire 	      sram_counter_rollover_flag,

		    input wire [2:0]  op_code,
		    input wire [6:0]  sram_counter_count_out,
		    input wire [1:0]  block_calculator_sram1_sd_no,

		    input wire [31:0] cache_out_block_no,
		    output reg 	      sram1_clear,
		    output reg 	      sram2_clear,
		    output reg [6:0]  cache_offset,
		    output reg [7:0]  cache_counter_rollover_val,
		    output reg 	      sram_data_sd_or_cache,
		    output reg 	      cache_counter_clear,
		    output reg 	      cache_counter_enable,
		    output reg 	      sram1_import_enable,
		    output reg 	      sram2_import_enable,
		    output reg 	      sd_start,
		    output reg 	      sd_mode,
		    output reg 	      sram_counter_clear,
		    output reg 	      sd_write_enable,
		    output reg 	      sram1_export_enable,
		    output reg 	      sram2_export_enable,
		    output reg 	      sram_counter_count_enable,
		    output reg [2:0]  cache_mode,
		    output reg 	      sd_read_enable, // read from sd
		    output reg 	      ahb_done,
		    output reg [31:0] cache_block_no,
		    output reg [2:0]  cache_in_data_select,
		    output reg [1:0]  cache_out_data_select,

		    output reg [8:0]  status,
		    input wire 	      block_no_counter_rollover_flag,
		    output reg 	      block_no_counter_enable,
		    output reg 	      block_no_counter_clear,

		    output reg [1:0]  block_calculator_mode,
		    output reg [1:0]  block_calculator_sd_no,
		    output reg 	      sram_offset_select,
		    output reg 	      sram_info_set
		    );

   typedef enum 		      bit [6:0] {IDLE,CHECK_EXISTS,EXISTS_RESULT,CACHE_DUMP_SRAM,SRAM_DUMP_SD_START,SRAM_DUMP_SD_START_WAIT,SRAM_DUMP_SD,SRAM_DUMP_SD_WAIT,SD_EXPORT_CACHE_SRAM2,
						 CHECK_PARITY_RESULT,SRAM2_EXPORT_CACHE,READ_CACHE,WRITE_CACHE,SD_ERROR,PARITY_ERROR,WAIT_AHB_START,SD_EXPORT_CACHE_SRAM2_START,
						 SET_STATUS_REG_READY,CLEAR_ALL_SD,RESTORE_SD,CHECK_OPERATION,CLEAR_BLOCK_CHECK_EXISTS,CLEAR_BLOCK_EXISTS_RESULT,WRITE_ZERO_CACHE,WRONG_OP, WRITE_ZERO_SD,CHECK_IF_CLEAR_FINISHED,RESTORE_SD1,RESTORE_SD2,RESTORE_SD3,CHECK_ALL_CLEAR,SRAM_DUMP_SD_START_CLEAR_ALL,SRAM_DUMP_SD_START_WAIT_CLEAR_ALL,SRAM_DUMP_SD_CLEAR_ALL,SRAM_DUMP_SD_WAIT_CLEAR_ALL,
						 SD_EXPORT_CACHE_SRAM2_START_CLEAR_BLOCK,SD_EXPORT_CACHE_SRAM2_START_WAIT_CLEAR_BLOCK,SD_EXPORT_CACHE_SRAM2_CLEAR_BLOCK,SRAM2_EXPORT_CACHE_CLEAR_BLOCK,RESTORE_BLOCK,
						 SRAM_DUMP_SD_CLEAR_ALL_GET_DATA_READY,LOAD_SD_SRAM1_SRAM2_START,LOAD_SD_SRAM1_SRAM2_START_WAIT,LOAD_SD_SRAM1_SRAM2,WRITE_SRAM_BACK_SD_START,WRITE_SRAM_BACK_SD_START_WAIT,
						 WRITE_SRAM_BACK_SD,WRITE_SRAM_BACK_SD_WAIT,RESTORE_BLOCK_START,LOAD_RESTORE_BLOCK_SRAM,LOAD_RESTORE_BLOCK_SRAM_START,LOAD_RESTORE_BLOCK_SRAM_START_WAIT,RESTORE_SD1_CARD_START,
						 RESTORE_SD2_CARD_START,RESTORE_SD3_CARD_START,CHECK_RESTORE_SD_FINISH,LOAD_ONE_OF_BLOCK_START,LOAD_ONE_OF_BLOCK_START_WAIT,LOAD_ONE_OF_BLOCK,WRITE_ONE_OF_BLOCK_START,
						 WRITE_ONE_OF_BLOCK_START_WAIT,WRITE_ONE_OF_BLOCK,CHECK_RESTORE_FINISH,WRITE_ONE_OF_BLOCK_WAIT} stateType; //WAIT_BLOCK_NO,SD_EXPORT_CACHE_SRAM2_START_WAIT removed

   stateType cur_state, next_state;

   always_comb begin
      sram_data_sd_or_cache = 0;
      cache_counter_clear = 0;
      cache_counter_enable = 0;
      sram1_import_enable = 0;
      sram2_import_enable = 0;
      sd_start = 0;
      sd_mode = 0;
      sram_counter_clear = 0;
      sd_write_enable = 0;
      sram1_export_enable = 0;
      sram2_export_enable = 0;
      sram_counter_count_enable = 0;
      sd_read_enable = 0;
      cache_block_no = 0;
      cache_mode = 0;
      cache_counter_rollover_val = 0;
      cache_offset = 0;
      ahb_done = 0;
      next_state = cur_state;
      cache_in_data_select = 0;
      cache_out_data_select = 0;
      status = {sd_error,3'b001};
      block_no_counter_enable = 1'b0;

      block_no_counter_clear = 1'b0;
      sram1_clear = 1'b0;
      sram2_clear = 1'b0;
      block_calculator_mode = 0;
      block_calculator_sd_no = 0;    
      sram_offset_select = 1'b0;
	sram_info_set = 1'b0;
      case (cur_state)
	IDLE:begin
	   if(ahb_ready == 1'b1) begin
	      next_state = CHECK_OPERATION;
	   end else begin
	      status = 9'd0;
	      next_state = cur_state;
	   end
	end

	CHECK_OPERATION: begin
	   block_calculator_mode = 2'd2;
	   if(op_code == 3'd0) begin
	      next_state = CHECK_EXISTS;
	   end else if (op_code == 3'd1) begin
	      next_state = CLEAR_ALL_SD;
	   end else if (op_code == 3'd2) begin
	      next_state = cur_state;//RESTORE_SD1_CARD_START;
	   end else if (op_code == 3'd3) begin
	      next_state = cur_state;//RESTORE_SD2_CARD_START;
	   end else if (op_code == 3'd4) begin
	      next_state = cur_state;//RESTORE_SD3_CARD_START;
	   end else if (op_code == 3'd5)begin
	      next_state = CLEAR_BLOCK_CHECK_EXISTS;
	   end else if(op_code == 3'd6) begin
	      next_state = cur_state;//RESTORE_BLOCK_START;
	   end else if(op_code == 3'd7) begin
	      next_state = IDLE;
	   end else begin
	      next_state = WRONG_OP;
	   end
	end

	CHECK_EXISTS: begin
	   cache_block_no = ahb_block_no;
	   sram_info_set = 1'b1;
	   block_calculator_mode = 2'd2;
	   next_state = EXISTS_RESULT;
	end

	EXISTS_RESULT:begin
	   cache_block_no = ahb_block_no;
	   if(exists == 1'b0 & full == 1'b1) begin
	      block_calculator_mode = 2'd1;
	      //cache_counter_clear = 1'b1;
	      //cache_counter_rollover_val = 8'd255;
	      next_state = CACHE_DUMP_SRAM;
	      sram_offset_select = 1'b1;
	      cache_mode = 3'b001;
	   end else if(exists == 1'b0 & full == 1'b0) begin
		block_calculator_mode = 2'd2;
		sram_info_set = 1'b1;
	      next_state = SD_EXPORT_CACHE_SRAM2_START;
	   end else begin
	      next_state = SET_STATUS_REG_READY;
	   end
	end

	CACHE_DUMP_SRAM:begin
	   cache_block_no = ahb_block_no;
	   //cache_counter_clear = 1'b0;
	   sram_offset_select = 1'b1;
	   if(full == 1'b0) begin
	      //cache_counter_enable = 1'b0;
	      cache_mode = 3'b000;
	      next_state = SRAM_DUMP_SD_START;
	   end else begin
	      //cache_counter_enable = 1'b1;
	      cache_mode = 3'b001;
	      block_calculator_mode = 2'd1;
	      sram_info_set = 1'b1;
	      if(cache_out_block_no[0] == 1'b0) begin
		 sram1_import_enable = 1'b1;
		 sram2_import_enable = 1'b0;
		 sram_data_sd_or_cache = 1'b1;
		 cache_out_data_select = 2'd1;
	      end else begin //dump second block
		 sram1_import_enable = 1'b0;
		 sram2_import_enable = 1'b1;
		 sram_data_sd_or_cache = 1'b1;
		 cache_out_data_select = 2'd2;
	      end
	      /*
	       if(cache_dump_half == 1'b0) begin //first block
	       sram1_import_enable = 1'b1;
	       sram2_import_enable = 1'b0;
	       sram_data_sd_or_cache = 1'b1;
	       cache_out_data_select = 2'd1;
	      end else begin //dump second block
	       sram1_import_enable = 1'b0;
	       sram2_import_enable = 1'b1;
	       sram_data_sd_or_cache = 1'b1;
	       cache_out_data_select = 2'd2;
	      end*/
	      next_state = cur_state;
	   end
	end


	SRAM_DUMP_SD_START: begin
	   sd_start = 1'b1;
	   sd_mode = 1'b1; // write into sd card
	   next_state = SRAM_DUMP_SD_START_WAIT;
	end

	SRAM_DUMP_SD_START_WAIT: begin
	   sd_mode = 1'b1;
	   sd_start = 1'b1;
	   if(sd_ready == 1'b0 && sd_error == 6'd0) begin			
	      next_state = cur_state;
	   end else if(sd_ready == 1'b1) begin
	      sram_counter_clear = 1'b1;
	      next_state = SRAM_DUMP_SD;
	   end else begin
	      next_state = SD_ERROR;
	   end
	end

	SRAM_DUMP_SD: begin
	   sram_counter_clear = 1'b0;
	   sd_mode = 1'b1; //not neccessary
	   if(sram_counter_rollover_flag == 1'b1) begin
	      sram_counter_count_enable = 1'b0;
	      block_calculator_mode = 2'd2;
	      sram_info_set = 1'b1;
	      next_state = SD_EXPORT_CACHE_SRAM2_START;
	   end else begin
	      sd_write_enable = 1'b1;
	      sram1_export_enable = 1'b1;
	      sram2_export_enable = 1'b1;
	      sram_data_sd_or_cache = 1'b0;
	      sram_counter_count_enable = 1'b1;
	      next_state = SRAM_DUMP_SD_WAIT;
	   end
	end

	SRAM_DUMP_SD_WAIT: begin
	   sd_mode = 1'b1; //not neccessary
	   sram_counter_count_enable = 1'b0;
	   if(sd_ready == 1'b0) begin
	      sd_write_enable = 1'b1;
	      sram1_export_enable = 1'b1;
	      sram2_export_enable = 1'b1;
	      sram_data_sd_or_cache = 1'b0;
	      next_state = cur_state;
	   end else
	     next_state = SRAM_DUMP_SD;
	end

	SD_EXPORT_CACHE_SRAM2_START: begin
	   sd_start = 1'b1;
	   sd_mode = 1'b0;
	   sram_counter_clear = 1'b1;
	   block_calculator_mode = 2'd2;
	   cache_block_no = ahb_block_no;
	   if(block_calculator_sram1_sd_no == 2'd1) begin
	      cache_in_data_select = 3'd4;
	   end else if(block_calculator_sram1_sd_no == 2'd2) begin
	      cache_in_data_select = 3'd5;
	   end else begin
	      cache_in_data_select = 3'd6;
	   end

	if(sd_ready == 1'b0 && sd_error == 6'd0) begin
	      next_state = cur_state;
	   end else if(sd_ready == 1'b1) begin
	      sram_counter_clear = 1'b1;
	      next_state = CHECK_PARITY_RESULT;
	   end else
	     next_state = SD_ERROR;
	end
/*
	SD_EXPORT_CACHE_SRAM2_START_WAIT: begin
	   sd_start = 1'b1;
	   sd_mode = 1'b0;
	   block_calculator_mode = 2'd2;
	   cache_block_no = ahb_block_no;
	   if(block_calculator_sram1_sd_no == 2'd1) begin
	      cache_in_data_select = 3'd4;
	   end else if(block_calculator_sram1_sd_no == 2'd2) begin
	      cache_in_data_select = 3'd5;
	   end else begin
	      cache_in_data_select = 3'd6;
	   end

	   
	end
*/
	CHECK_PARITY_RESULT: begin
	   cache_mode = 3'b010;
	   cache_block_no = {ahb_block_no[31:1],1'b0};
	   cache_offset = sram_counter_count_out;
	   block_calculator_mode = 2'd2;
	   if(valid == 1'b1) begin

	      if(block_calculator_sram1_sd_no == 2'd1) begin
		 cache_in_data_select = 3'd4;
	      end else if(block_calculator_sram1_sd_no == 2'd2) begin
		 cache_in_data_select = 3'd5;
	      end else begin
		 cache_in_data_select = 3'd6;
	      end

	      sram2_import_enable = 1'b1;
	      sram_data_sd_or_cache = 1'b0;
	      next_state = SD_EXPORT_CACHE_SRAM2;
	      sram_counter_count_enable = 1'b1;
	   end else begin
	      next_state = PARITY_ERROR;
	   end
	end

	SD_EXPORT_CACHE_SRAM2: begin
	   block_calculator_mode = 2'd2;
	   if(block_calculator_sram1_sd_no == 2'd1) begin
	      cache_in_data_select = 3'd4;
	   end else if(block_calculator_sram1_sd_no == 2'd2) begin
	      cache_in_data_select = 3'd5;
	   end else begin
	      cache_in_data_select = 3'd6;
	   end


	   if(sram_counter_rollover_flag == 1'b0) begin
	      sd_read_enable = 1'b1;
	      cache_mode = 3'b010;
	      cache_block_no = {ahb_block_no[31:1],1'b0};
	      cache_offset = sram_counter_count_out;
	      if(sd_ready == 1'b1)
		next_state = CHECK_PARITY_RESULT;
	      else
		next_state = cur_state;
	   end else begin
	      //next start to put sram2 data to cache			
	      sram_counter_clear = 1'b1;
	      next_state = SRAM2_EXPORT_CACHE;
	   end
	end

	SRAM2_EXPORT_CACHE: begin
	   sram_counter_clear = 1'b0;
	   if(sram_counter_rollover_flag == 1'b0) begin
	      cache_mode = 3'b010;
	      cache_block_no = {ahb_block_no[31:1],1'b1};
	      cache_in_data_select = 3'd3;
	      cache_offset = sram_counter_count_out;
	      sram2_export_enable = 1'b1;
	      sram_data_sd_or_cache = 1'b1;
	      sram_counter_count_enable = 1'b1;
	      next_state = cur_state;
	   end else begin
	      next_state = SET_STATUS_REG_READY;
	   end
	end
	
	SET_STATUS_REG_READY: begin
	   cache_counter_clear = 1'b1;
	   cache_counter_rollover_val = ahb_length - 1;
	   cache_block_no = ahb_block_no;
	   status = 9'd0;
	   next_state = WAIT_AHB_START;
	end

	WAIT_AHB_START: begin
	   cache_counter_rollover_val = ahb_length - 1;
	   cache_offset = cache_counter_count_out[6:0] + ahb_offset;
	   cache_block_no = ahb_block_no;
	   if(ahb_start == 1'b1) begin
	      if(mode == 1'b1) begin
		 cache_mode = 3'b011;
		 next_state = READ_CACHE;
	      end else begin
		 cache_mode = 3'b110;
		 next_state = WRITE_CACHE;
	      end
	   end else
	     next_state = cur_state;
	end

	READ_CACHE: begin
	   cache_counter_rollover_val = ahb_length - 1;
	cache_offset = cache_counter_count_out[6:0] + ahb_offset;
	   cache_block_no = ahb_block_no;
	   if(cache_counter_rollover_flag == 1'b1)
	     next_state = IDLE;
	   else begin
	      cache_mode = 3'b011;
	      cache_counter_enable = 1'b1;
	      cache_out_data_select = 2'd3;
	      cache_offset = cache_counter_count_out[6:0] + ahb_offset;
	      next_state = WAIT_AHB_START;
	      ahb_done = 1'b1;
	   end
	end

	WRITE_CACHE: begin
	   cache_counter_rollover_val = ahb_length - 1;
	   cache_block_no = ahb_block_no;
	cache_offset = cache_counter_count_out[6:0] + ahb_offset;
	   if(cache_counter_rollover_flag == 1'b1)
	     next_state = IDLE;
	   else begin
	      cache_mode = 3'b110;
	      cache_counter_enable = 1'b1;
	      cache_in_data_select = 3'd1;
	      cache_offset = cache_counter_count_out[6:0] + ahb_offset;
	      next_state = WAIT_AHB_START;
	      ahb_done = 1'b1;
	   end
	end

	SD_ERROR: begin
	   if(ahb_ready == 0) begin
	      status = {sd_error,3'b000};
	      next_state = cur_state;
	   end else begin
	      next_state = CHECK_OPERATION;
	   end
	end

	PARITY_ERROR: begin
	   if(ahb_ready == 0) begin
	      status = {sd_error,3'b010};
	      next_state = cur_state;
	   end else begin
	      next_state = CHECK_OPERATION;
	   end
	end

	WRONG_OP: begin
	   if(ahb_ready == 0) begin
	      status = {sd_error,3'b100};
	      next_state = cur_state;
	   end else begin
	      next_state = CHECK_OPERATION;
	   end
	end

	
	//start of clear all disks
	CLEAR_ALL_SD: begin
	   block_no_counter_clear = 1'b1;
	   //tell sram1, sram2, cache to clear
	   sram1_clear = 1'b1;
	   sram2_clear = 1'b1;
	   cache_mode = 3'b111;
	   next_state = CHECK_ALL_CLEAR;
	end

	CHECK_ALL_CLEAR: begin
	   block_no_counter_clear = 1'b0;
	   if(block_no_counter_rollover_flag != 1'b1) begin
	      block_calculator_mode = 2'd3;
	      next_state = SRAM_DUMP_SD_START_CLEAR_ALL;
	   end else begin
	      next_state = IDLE;
	   end
	end

	SRAM_DUMP_SD_START_CLEAR_ALL: begin
	   sd_start = 1'b1;
	   sd_mode = 1'b1; // write into sd card
	   block_calculator_mode = 2'd3;
	   sram_info_set = 1'b1;
	   next_state = SRAM_DUMP_SD_START_WAIT_CLEAR_ALL;
	end

	SRAM_DUMP_SD_START_WAIT_CLEAR_ALL: begin
	   sram_info_set = 1'b1;
	   sd_mode = 1'b1;
	   sd_start = 1'b1;
	   if(sd_ready == 1'b0 && sd_error == 6'd0) begin
	      next_state = cur_state;
	   end else if(sd_ready == 1'b1) begin
	      sram_counter_clear = 1'b1;
	      next_state = SRAM_DUMP_SD_CLEAR_ALL;
	   end else begin
	      next_state = SD_ERROR; 
	   end
	end

	SRAM_DUMP_SD_CLEAR_ALL: begin
	   sd_mode = 1'b1;
	   sram_counter_clear = 1'b0;
	   if(sram_counter_rollover_flag == 1'b1) begin
	      sram_counter_count_enable = 1'b0;
	      block_no_counter_enable = 1'b1;
	      next_state = CHECK_ALL_CLEAR;
	   end else begin
	      sd_write_enable = 1'b1;
	      sram1_export_enable = 1'b1;
	      sram2_export_enable = 1'b1;
	      sram_counter_count_enable = 1'b1;
	      sram_data_sd_or_cache = 1'b0;
	      next_state = SRAM_DUMP_SD_WAIT_CLEAR_ALL;
	   end
	end

	SRAM_DUMP_SD_WAIT_CLEAR_ALL: begin
	   sram1_export_enable = 1'b1;
	   sram2_export_enable = 1'b1;
	   sram_counter_count_enable = 1'b0;
	   sd_write_enable = 1'b1;
	   sram_data_sd_or_cache = 1'b0;
	   if(sd_ready == 1'b0)
	     next_state = cur_state;
	   else
	     next_state = SRAM_DUMP_SD_CLEAR_ALL;
	end
	//end of clear all disks
	//start of clear one block
	CLEAR_BLOCK_CHECK_EXISTS: begin
	   cache_block_no = ahb_block_no;
	   next_state = CLEAR_BLOCK_EXISTS_RESULT;
	end
	
	CLEAR_BLOCK_EXISTS_RESULT:begin
	   cache_block_no = ahb_block_no;
	   cache_counter_clear = 1'b1;
	   cache_counter_rollover_val = 7'd127;
	   if(exists == 1'b1) begin
	      next_state = WRITE_ZERO_CACHE;
	   end else begin
	      next_state = LOAD_SD_SRAM1_SRAM2_START;
	   end
	end

	WRITE_ZERO_CACHE: begin
	   cache_counter_rollover_val = 7'd127;
	   if(cache_counter_rollover_flag != 1'b1) begin
	      cache_mode = 3'b110;
	      cache_counter_clear = 1'b0;
	      cache_counter_enable = 1'b1;
	      cache_in_data_select = 3'd0;
	      cache_offset = cache_counter_count_out;
	      next_state = cur_state;
	   end else begin
	      next_state = IDLE;
	   end
	end
	//end of clear one block in cache
	LOAD_SD_SRAM1_SRAM2_START: begin
	   sd_start = 1'b1;
	   sd_mode = 1'b0;
	   sram_counter_clear = 1'b1;
	   sram_info_set = 1'b1;
	   block_calculator_mode = 2'd2;
	   next_state = LOAD_SD_SRAM1_SRAM2_START_WAIT;
	end


	LOAD_SD_SRAM1_SRAM2_START_WAIT: begin
	   sd_start = 1'b1;
	   sd_mode = 1'b0;
	   if(sd_ready == 1'b0 && sd_error == 6'd0) begin
	      next_state = cur_state;
	   end else if(sd_ready == 1'b1) begin
	      sram_counter_clear = 1'b1;
	      next_state = LOAD_SD_SRAM1_SRAM2;
	   end else begin
	      next_state = SD_ERROR;
	   end
	end

	LOAD_SD_SRAM1_SRAM2: begin
	   block_calculator_mode = 2'd2;
	   sram_counter_clear = 1'b0;
	   if(sram_counter_rollover_flag == 1'b0) begin
	      sd_read_enable = 1'b1;
	      sram1_import_enable = 1'b1;
	      sram2_import_enable = 1'b1;
	      sram_offset_select = 1'b0;
	      sram_data_sd_or_cache = 1'b0;
	      if(sd_ready == 1'b1)
		sram_counter_count_enable = 1'b1;
	      else
		sram_counter_count_enable = 1'b0;
	      next_state = cur_state;
	   end else begin
	      sram_counter_clear = 1'b1;
	      if(ahb_block_no[0] == 0)
		sram1_clear = 1'b1;
	      else
		sram2_clear = 1'b1;
	      next_state = WRITE_SRAM_BACK_SD_START;
	   end
	end

	WRITE_SRAM_BACK_SD_START: begin
	   sd_start = 1'b1;
	   sd_mode = 1'b1; // write into sd card
	   //no need to set block and sd information since it's the same after load the data in
	   next_state = WRITE_SRAM_BACK_SD_START_WAIT;
	end

	WRITE_SRAM_BACK_SD_START_WAIT: begin
	   sd_start = 1'b1;
	   sd_mode = 1'b1;
	   if(sd_ready == 1'b0 && sd_error == 6'd0) begin			
	      next_state = cur_state;
	   end else if(sd_ready == 1'b1) begin
	      sram_counter_clear = 1'b1;
	      next_state = WRITE_SRAM_BACK_SD;
	   end else begin
	      next_state = SD_ERROR;
	   end
	end

	WRITE_SRAM_BACK_SD: begin
	   sram_counter_clear = 1'b0;
	   if(sram_counter_rollover_flag == 1'b1) begin
	      sram_counter_count_enable = 1'b0;
	      next_state = IDLE;
	   end else begin
	      sd_write_enable = 1'b1;
	      sram1_export_enable = 1'b1;
	      sram2_export_enable = 1'b1;
	      sram_counter_count_enable = 1'b1;
	      sram_data_sd_or_cache = 1'b0;
	      next_state = WRITE_SRAM_BACK_SD_WAIT;
	   end
	end

	WRITE_SRAM_BACK_SD_WAIT: begin
	   sram_counter_count_enable = 1'b0;
	   sd_write_enable = 1'b1;
	   sram1_export_enable = 1'b1;
	   sram2_export_enable = 1'b1;
	   sram_data_sd_or_cache = 1'b0;
	   if(sd_ready == 1'b0)
	     next_state = cur_state;
	   else
	     next_state = WRITE_SRAM_BACK_SD;
	end
	//end of clear one block in sd card
	
	//start of restore one block in sd card
	RESTORE_BLOCK_START: begin
	   sram_info_set = 1'b1;
	   block_calculator_mode = 2'd0;
	   next_state = LOAD_RESTORE_BLOCK_SRAM;
	end

	LOAD_RESTORE_BLOCK_SRAM_START: begin
	   block_calculator_mode = 2'd0;
	   sd_start = 1'b1;
	   sd_mode = 1'b0;
	   sram_counter_clear = 1'b1;
	   next_state = LOAD_RESTORE_BLOCK_SRAM_START_WAIT;
	end


	LOAD_RESTORE_BLOCK_SRAM_START_WAIT: begin
	   sd_start = 1'b1;
	   sd_mode = 1'b0;
	   if(sd_ready == 1'b0) begin
	      next_state = cur_state;
	   end else if(sd_ready == 1'b1) begin
	      next_state = LOAD_RESTORE_BLOCK_SRAM;
	   end
	end

	LOAD_RESTORE_BLOCK_SRAM: begin
	   sram_counter_clear = 1'b0;
	   if(sram_counter_rollover_flag == 1'b0) begin
	      sd_read_enable = 1'b1;
	      sram1_import_enable = 1'b1;
	      sram2_import_enable = 1'b1;
	      sram_offset_select = 1'b0;
	      sram_data_sd_or_cache = 1'b0;
	      if(sd_ready == 1'b1)
		sram_counter_count_enable = 1'b1;
	      else
		sram_counter_count_enable = 1'b0;
	      next_state = cur_state;
	   end else begin
	      sram_counter_clear = 1'b1;
	      next_state = WRITE_SRAM_BACK_SD_START; //should be able to do this
	   end
	end
	//end of restore one block in sd card

	//start of restore one sd card
	RESTORE_SD1_CARD_START: begin
	   block_no_counter_clear = 1'b1;
	   block_calculator_mode  = 2'd3;
	   block_calculator_sd_no = 2'd1;
	   sram_info_set = 1'b1;
	   next_state = CHECK_RESTORE_SD_FINISH;
	end

	RESTORE_SD2_CARD_START: begin
	   block_no_counter_clear = 1'b1;
	   block_calculator_mode  = 2'd3;
	   block_calculator_sd_no = 2'd2;
	   sram_info_set = 1'b1;
	   next_state = CHECK_RESTORE_SD_FINISH;
	end

	RESTORE_SD3_CARD_START: begin
	   block_no_counter_clear = 1'b1;
	   block_calculator_mode  = 2'd3;
	   block_calculator_sd_no = 2'd3;
	   sram_info_set = 1'b1;
	   next_state = CHECK_RESTORE_SD_FINISH;
	end


	CHECK_RESTORE_SD_FINISH: begin
	   block_calculator_mode  = 2'd3;
	   if(block_no_counter_rollover_flag == 1'b1) begin
	      next_state = IDLE;
	   end else begin
	      next_state = LOAD_ONE_OF_BLOCK_START;
	   end
	end

	LOAD_ONE_OF_BLOCK_START: begin
	   block_calculator_mode = 2'd3;
	   //need another signal to tell that block remeber the 

	   sd_start = 1'b1;
	   sd_mode = 1'b0;
	   sram_counter_clear = 1'b1;
	   next_state = LOAD_ONE_OF_BLOCK_START_WAIT;
	end

	LOAD_ONE_OF_BLOCK_START_WAIT: begin
	   sd_start = 1'b1;
	   if(sd_ready == 1'b0) begin
	      next_state = cur_state;
	   end else if(sd_ready == 1'b1) begin
	      sram_counter_clear = 1'b1;
	      next_state = LOAD_ONE_OF_BLOCK;
	   end
	end

	LOAD_ONE_OF_BLOCK: begin
	   sram_counter_clear = 1'b0;
	   if(sram_counter_rollover_flag == 1'b0) begin
	      sd_read_enable = 1'b1;
	      sram1_import_enable = 1'b1;
	      sram2_import_enable = 1'b1;
	      sram_offset_select = 1'b0;
	      sram_data_sd_or_cache = 1'b0;
	      if(sd_ready == 1'b1)
		sram_counter_count_enable = 1'b1;
	      else
		sram_counter_count_enable = 1'b0;
	      next_state = cur_state;
	   end else begin
	      sram_counter_clear = 1'b1;
	      next_state = WRITE_ONE_OF_BLOCK_START;
	   end
	end

	WRITE_ONE_OF_BLOCK_START: begin
	   sd_start = 1'b1;
	   sd_mode = 1'b1; // write into sd card
	   next_state = WRITE_ONE_OF_BLOCK_START_WAIT;
	end

	WRITE_ONE_OF_BLOCK_START_WAIT: begin
	   sd_start = 1'b1;
	   sd_mode = 1'b1;
	   if(sd_ready == 1'b0 && sd_error == 6'd0) begin			
	      next_state = cur_state;
	   end else if(sd_ready == 1'b1) begin
	      sram_counter_clear = 1'b1;
	      block_no_counter_enable = 1'b1;
	      next_state = WRITE_ONE_OF_BLOCK;
	   end else begin
	      next_state = SD_ERROR;
	   end
	end

	WRITE_ONE_OF_BLOCK: begin
	   sram_counter_clear = 1'b0;
	   sd_mode = 1'b1; //should not neccessary
	   if(sram_counter_rollover_flag == 1'b1) begin
	      sram_counter_count_enable = 1'b0;
	      next_state = CHECK_RESTORE_SD_FINISH;
	   end else begin
	      sd_write_enable = 1'b1;
	      sram1_export_enable = 1'b1;
	      sram2_export_enable = 1'b1;
	      sram_counter_count_enable = 1'b1;
	      sram_data_sd_or_cache = 1'b0;
	      next_state = WRITE_ONE_OF_BLOCK_WAIT;
	   end
	end

	WRITE_ONE_OF_BLOCK_WAIT: begin
	   sd_mode = 1'b1; //should not neccessary
	   sram_counter_count_enable = 1'b0;
	   sd_write_enable = 1'b1;
	   sram1_export_enable = 1'b1;
	   sram2_export_enable = 1'b1;
	   sram_counter_count_enable = 1'b1;
	   sram_data_sd_or_cache = 1'b0;
	   if(sd_ready == 1'b0)
	     next_state = cur_state;
	   else
	     next_state = WRITE_ONE_OF_BLOCK;
	end
	//end of restore one sd card
      endcase
   end

   always_ff@(posedge clk, negedge n_rst) begin
      if(n_rst == 0) begin
	 cur_state <= IDLE;
      end
      else begin
	 cur_state <= next_state;
      end
   end

endmodule
