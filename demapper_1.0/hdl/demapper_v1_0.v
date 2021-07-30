
`timescale 1 ns / 1 ps

	module demapper_v1_0 #
	(

		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,

		// Parameters of Axi Master Bus Interface M00_AXIS
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_START_COUNT	= 32
	)
	(

		// Ports of Axi Slave Bus Interface S00_AXIS
		input wire  s00_axis_aclk,
		input wire  s00_axis_aresetn,
		output wire  s00_axis_tready,
		input wire [63 : 0] s00_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
		input wire  s00_axis_tlast,
		input wire  s00_axis_tvalid,

		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk,
		input wire  m00_axis_aresetn,
		output wire  m00_axis_tvalid,
		output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready
	);

    reg [9 : 0] count = 0;
    assign s00_axis_tready = m00_axis_tready;
    assign m00_axis_tdata = {s00_axis_tdata[58], s00_axis_tdata[49 : 35],  s00_axis_tdata[26], s00_axis_tdata[17 : 3]};
    assign m00_axis_tvalid = s00_axis_tvalid && (((count > 0 && count < 401) || (count >= 623 && count < 1023)) ? 1 : 0);
    
    always @ (posedge s00_axis_aclk) begin
        if(~s00_axis_aresetn) begin
            count <= 0;
        end
        else begin
            if(s00_axis_tvalid && m00_axis_tready) begin
                count <= count + 1;
            end
        end
        
    end

	endmodule
