`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/06/2021 11:37:18 AM
// Design Name: 
// Module Name: test_framer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test_framer(

    );
    
    
    reg  s_axis_data_aclk = 0;
    reg  aresetn;
    wire  s_axis_data_tready;
    wire [32-1 : 0] s_axis_data_tdata;
    wire [(32/8)-1 : 0] s_axis_data_tstrb;
    wire  s_axis_data_tlast;
    wire  s_axis_data_tvalid;

    // Ports of Axi Master Bus Interface M_AXIS_DATA
    wire  m_axis_data_aclk;
    wire  m_axis_data_aresetn;
    wire  m_axis_data_tvalid;
    wire [40-1 : 0] m_axis_data_tdata;
    wire [(40/8)-1 : 0] m_axis_data_tstrb;
    wire  m_axis_data_tlast;
    wire  m_axis_data_tready;

    // Ports of Axi Slave Bus Interface S_AXIS_CONFIG
    wire  s_axis_config_aclk;
    wire  s_axis_config_aresetn;
    wire  s_axis_config_tready;
    wire [32-1 : 0] s_axis_config_tdata;
    wire [(32/8)-1 : 0] s_axis_config_tstrb;
    wire  s_axis_config_tlast;
    wire  s_axis_config_tvalid;
    
    OFDM_Framer_v1_0 OFDM_Framer_v1_0_inst(
        .s_axis_data_aclk(s_axis_data_aclk),
		.s_axis_data_aresetn(aresetn),
		.s_axis_data_tready(s_axis_data_tready),
		.s_axis_data_tdata(s_axis_data_tdata),
		.s_axis_data_tstrb(s_axis_data_tstrb),
		.s_axis_data_tlast(s_axis_data_tlast),
		.s_axis_data_tvalid(s_axis_data_tvalid),

		// Ports of Axi Master Bus Interface M_AXIS_DATA
		.m_axis_data_aclk(m_axis_data_aclk),
		.m_axis_data_aresetn(aresetn),
		.m_axis_data_tvalid(m_axis_data_tvalid),
		.m_axis_data_tdata(m_axis_data_tdata),
		.m_axis_data_tstrb(m_axis_data_tstrb),
		.m_axis_data_tlast(m_axis_data_tlast),
		.m_axis_data_tready(m_axis_data_tready),

		// Ports of Axi Slave Bus Interface S_AXIS_CONFIG
		.s_axis_config_aclk(s_axis_config_aclk),
		.s_axis_config_aresetn(aresetn),
		.s_axis_config_tready(s_axis_config_tready),
		.s_axis_config_tdata(s_axis_config_tdata),
		.s_axis_config_tstrb(s_axis_config_tstrb),
		.s_axis_config_tlast(s_axis_config_tlast),
		.s_axis_config_tvalid(s_axis_config_tvalid)
    );
    
    reg [31 : 0] sync_word [0 : 24];
    reg [31 : 0] shift_freq [0 : 1023];
    reg [7 : 0] sw_count = 0; 
    reg [9 : 0] sf_count = 0;
    reg start = 0;
    
    assign m_axis_data_aclk = s_axis_data_aclk;
    assign s_axis_config_aclk = s_axis_data_aclk;
    
    assign s_axis_config_tdata = sync_word[sw_count];
    assign s_axis_data_tdata = shift_freq[sf_count];
    
    assign s_axis_data_tvalid = !s_axis_config_tready && sf_count < 450;
    assign s_axis_config_tvalid = start && (sw_count < 25);
    
    initial begin
        forever #5 s_axis_data_aclk = ~s_axis_data_aclk;
    end
    
    always @(posedge s_axis_data_aclk) begin
        if(start && s_axis_config_tready && s_axis_config_tvalid) begin
                sw_count <= sw_count + 1;
        end
        else if(start && !s_axis_config_tready && s_axis_data_tready)
            if(sw_count == 25 && sf_count < 450 ) begin
                sf_count <= sf_count + 1;
            end
    end
    
    assign m_axis_data_tready = 1;
    
        initial 
        $readmemh("/home/george/pout32.txt", sync_word, 0, 24);

    initial 
        $readmemh("/home/george/freq_shift.txt", shift_freq, 0, 1023);
        
        
    initial begin
        aresetn = 0;
        #40
        aresetn = 1;
        start = 1;
    
    end
		
		
endmodule
