// $Id: $mg97
// File name:   cache_data_in_mux.sv
// Created:     12/8/2015
// Author:      Renjun Zheng
// Lab Section: 337-007
// Version:     1.0  Initial Design Entry
// Description: select data source goes to cache

module cache_data_in_mux(
	input wire [31:0] ahb_data,//1
	input wire [31:0] sram1_data,//2
	input wire [31:0] sram2_data,//3
	input wire [31:0] sd1_data,//4
	input wire [31:0] sd2_data,//5
	input wire [31:0] sd3_data,//6
	//output 0 when select out is 0
	input wire [2:0] select_out,
	output reg [31:0] output_data
);

always_comb begin
	if(select_out == 3'd0)
		output_data = 32'd0;
	else if(select_out == 3'd1)
		output_data = ahb_data;
	else if(select_out == 3'd2)
		output_data = sram1_data;
	else if(select_out == 3'd3)
		output_data = sram2_data;
	else if(select_out == 3'd4)
		output_data = sd1_data;
	else if(select_out == 3'd5)
		output_data = sd2_data;
	else
		output_data = sd3_data;
end

//	assign output_data = (select_out == 2'd0)? 32'd0 : ((select_out == 2'd1) ? sram1_data: ((select_out == 2'd2) ? sram2_data: ahb_data));

endmodule
