
`timescale 1 ns / 1 ps

	module medium_emulator_v1_0 #
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

		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk,
		input wire  m00_axis_aresetn,
		output wire  m00_axis_tvalid,
		output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready,
		
		input wire start
	);

    reg [C_M00_AXIS_TDATA_WIDTH - 1 : 0] samp_cnt = 0;
    reg [C_M00_AXIS_TDATA_WIDTH - 1 : 0] seed = 32'h00000001; //32'hb5a328f4;
    reg go = 0;
    
    always@(posedge m00_axis_aclk) begin
        if(start)
            go <= 1;
    end
    
    always@(posedge m00_axis_aclk) begin
        if(m00_axis_tready && go)
            samp_cnt = samp_cnt + 1;
    end
    
    assign s00_axis_tready = m00_axis_tready;
    
    assign m00_axis_tdata = go ? (m00_axis_tready ?( s00_axis_tvalid ? s00_axis_tdata :
                    (seed)) : seed ) : 32'h0;
    assign m00_axis_tvalid = go;

	endmodule
