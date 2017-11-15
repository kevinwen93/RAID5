module sd_error_combine(
	input wire [1:0] sd1_error,
	input wire [1:0] sd2_error,
	input wire [1:0] sd3_error,
	output wire [5:0] sd_error
);

assign sd_error = {sd1_error, sd2_error, sd3_error};

endmodule
