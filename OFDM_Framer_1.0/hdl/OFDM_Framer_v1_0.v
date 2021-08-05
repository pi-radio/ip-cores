
`timescale 1 ns / 1 ps

	module OFDM_Framer_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S_AXIS_DATA
		parameter integer C_S_AXIS_DATA_TDATA_WIDTH	= 32,

		// Parameters of Axi Master Bus Interface M_AXIS_DATA
		parameter integer C_M_AXIS_DATA_TDATA_WIDTH	= 40,
		parameter integer C_M_AXIS_DATA_START_COUNT	= 32,

		// Parameters of Axi Slave Bus Interface S_AXIS_CONFIG
		parameter integer C_S_AXIS_CONFIG_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S_AXIS_DATA
		input wire  s_axis_data_aclk,
		input wire  s_axis_data_aresetn,
		output wire  s_axis_data_tready,
		input wire [C_S_AXIS_DATA_TDATA_WIDTH-1 : 0] s_axis_data_tdata,
		input wire [(C_S_AXIS_DATA_TDATA_WIDTH/8)-1 : 0] s_axis_data_tstrb,
		input wire  s_axis_data_tlast,
		input wire  s_axis_data_tvalid,

		// Ports of Axi Master Bus Interface M_AXIS_DATA
		input wire  m_axis_data_aclk,
		input wire  m_axis_data_aresetn,
		output wire  m_axis_data_tvalid,
		output wire [C_M_AXIS_DATA_TDATA_WIDTH-1 : 0] m_axis_data_tdata,
		output wire [(C_M_AXIS_DATA_TDATA_WIDTH/8)-1 : 0] m_axis_data_tstrb,
		output wire  m_axis_data_tlast,
		input wire  m_axis_data_tready,

		// Ports of Axi Slave Bus Interface S_AXIS_CONFIG
		input wire  s_axis_config_aclk,
		input wire  s_axis_config_aresetn,
		output wire  s_axis_config_tready,
		input wire [C_S_AXIS_CONFIG_TDATA_WIDTH-1 : 0] s_axis_config_tdata,
		input wire [(C_S_AXIS_CONFIG_TDATA_WIDTH/8)-1 : 0] s_axis_config_tstrb,
		input wire  s_axis_config_tlast,
		input wire  s_axis_config_tvalid
	);
	
	wire [799 : 0] sync_word;
	
	sync_word_module #(
       .USED_CARRIERS(800)
       ) sync_word_mod_inst (
        .s_axis_config_aclk(s_axis_config_aclk),
		.s_axis_config_aresetn(s_axis_config_aresetn),
		.s_axis_config_tready(s_axis_config_tready),
		.s_axis_config_tdata(s_axis_config_tdata),
		.s_axis_config_tstrb(s_axis_config_tstrb),
		.s_axis_config_tlast(s_axis_config_tlast),
		.s_axis_config_tvalid(s_axis_config_tvalid),
		.sync_word(sync_word)
       );
            
   data_module data_module_inst(
   		.s_axis_data_aclk(s_axis_data_aclk),
		.s_axis_data_aresetn(s_axis_data_aresetn),
		.s_axis_data_tready(s_axis_data_tready),
		.s_axis_data_tdata(s_axis_data_tdata),
		.s_axis_data_tstrb(s_axis_data_tstrb),
		.s_axis_data_tlast(s_axis_data_tlast),
		.s_axis_data_tvalid(s_axis_data_tvalid),
		.sync_word(sync_word),
		.sync_word_ready(!s_axis_config_tready),
		.m_axis_data_tvalid(m_axis_data_tvalid),
		.m_axis_data_tdata(m_axis_data_tdata),
		.m_axis_data_tstrb(m_axis_data_tstrb),
		.m_axis_data_tlast(m_axis_data_tlast),
		.m_axis_data_tready(m_axis_data_tready)
   );

	endmodule
