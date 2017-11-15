// $Id: $mg97
// File name:   sd_data_out_select.sv
// Created:     12/9/2015
// Author:      Renjun Zheng
// Lab Section: 337-007
// Version:     1.0  Initial Design Entry
// Description: select which sram that sd data goes to

module sd_data_out_select(
	input wire [31:0] sd1_data,
	input wire [31:0] sd2_data,
	input wire [31:0] sd3_data,
	input wire [1:0] selectid,
	input wire [1:0] sram1sd, // data stored in sram that used to select
	input wire [1:0] sram2sd,
	output wire [31:0] output_data
);

assign output_data = (selectid == sram1sd) ? sd1_data : ((selectid == sram2sd) ? sd2_data : sd3_data);

endmodule
