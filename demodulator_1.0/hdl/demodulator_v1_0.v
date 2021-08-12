// Can this be done one cycle earlier?

`timescale 1 ns / 1 ps

	module demodulator_v1_0 #
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
		input wire  m00_axis_tready
	);
	
	reg [4 : 0] bit_index = 0;
	reg [C_M00_AXIS_TDATA_WIDTH-1 : 0] byte_out = 0;
	reg byte_ready = 0;
	wire signed [15 : 0] i_data;
	reg [10 : 0] count_samples;
	
	
    assign s00_axis_tready = m00_axis_tready;
    assign m00_axis_tdata = byte_out;
    assign i_data = s00_axis_tdata[15 : 0];
    assign m00_axis_tvalid = byte_ready; 
    assign m00_axis_tlast = m00_axis_tvalid && (count_samples == 19);
    
    always @(posedge s00_axis_aclk) begin
        if(!s00_axis_aresetn)
            count_samples <= 0;
        else begin
            if(byte_ready)
                if(count_samples < 19)
                    count_samples <= count_samples + 1;
                else if(count_samples == 19)
                    count_samples <= 0;
        end
    end
    
    always @(posedge s00_axis_aclk) begin
        if(!s00_axis_aresetn) begin
            byte_ready <= 0;
            bit_index <= 0;
        end
        if(byte_ready)
            byte_ready <= 0;
        if(s00_axis_tvalid && m00_axis_tready) begin
                if(i_data >= 0)
                    byte_out[bit_index] <= 1;
                else
                    byte_out[bit_index] <= 0;
                bit_index <= bit_index + 1;
                if(bit_index == 5'd31)
                    byte_ready <= 1;
            end
    end

	endmodule
