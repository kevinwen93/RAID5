// $Id: $mg97
// File name:   cache_data_out_mux
// Created:     12/8/2015
// Author:      Renjun Zheng
// Lab Section: 337-007
// Version:     1.0  Initial Design Entry
// Description: select which output cache data goes to

module cache_data_out_mux(
	input wire [31:0] input_data,
	input wire [1:0] select_out,
	output reg [31:0] ahb_data,
	output reg [31:0] sram1_data,
	output reg [31:0] sram2_data
);

always_comb begin
	sram1_data = 32'd0;
	sram2_data = 32'd0;
	ahb_data = 32'd0;
	if(select_out == 2'd1) begin
		sram1_data = input_data;
	end else if(select_out == 2'd2) begin
		sram2_data = input_data;
	end else if(select_out == 2'd3) begin
		ahb_data = input_data;
	end
end
endmodule
