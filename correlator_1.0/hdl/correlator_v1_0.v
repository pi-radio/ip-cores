
`timescale 1 ns / 1 ps

	module correlator_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,

		// Parameters of Axi Master Bus Interface M00_AXIS
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_START_COUNT	= 32
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXIS
		input wire  s00_axis_aclk,
		input wire  s00_axis_aresetn,
		output wire  s00_axis_tready,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
		input wire  s00_axis_tlast,
		input wire  s00_axis_tvalid,
		
		// Ports of Axi Slave Config Bus Interface S00_AXIS
		input wire  s00_axis_config_aclk,
		input wire  s00_axis_config_aresetn,
		output wire  s00_axis_config_tready,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_config_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_config_tstrb,
		input wire  s00_axis_config_tlast,
		input wire  s00_axis_config_tvalid,

		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk,
		input wire  m00_axis_aresetn,
		output wire  m00_axis_tvalid,
		output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready,

		
		
		output wire [31 : 0] a,
		output wire [31 : 0] b,
		output wire [79 : 0] test_out
	);
// Instantiation of Axi Bus Interface S00_AXIS
	correlator_v1_0_S00_AXIS # ( 
		.C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
	) correlator_v1_0_S00_AXIS_inst (
		.S_AXIS_ACLK(s00_axis_aclk),
		.S_AXIS_ARESETN(s00_axis_aresetn),
		.S_AXIS_TREADY(s00_axis_tready),
		.S_AXIS_TDATA(s00_axis_tdata),
		.S_AXIS_TSTRB(s00_axis_tstrb),
		.S_AXIS_TLAST(s00_axis_tlast),
		.S_AXIS_TVALID(s00_axis_tvalid),
		.S_AXIS_CONFIG_TREADY(s00_axis_config_tready),
		.S_AXIS_CONFIG_TDATA(s00_axis_config_tdata),
		.S_AXIS_CONFIG_TSTRB(s00_axis_config_tstrb),
		.S_AXIS_CONFIG_TLAST(s00_axis_config_tlast),
		.S_AXIS_CONFIG_TVALID(s00_axis_config_tvalid),
	    .M_AXIS_TVALID(m00_axis_tvalid),
		.M_AXIS_TDATA(m00_axis_tdata),
		.M_AXIS_TSTRB(m00_axis_tstrb),
		.M_AXIS_TLAST(m00_axis_tlast),
		.M_AXIS_TREADY(m00_axis_tready),
		.a(a),
		.b(b),
		.out(test_out)
	);

	// Add user logic here

	// User logic ends

	endmodule
