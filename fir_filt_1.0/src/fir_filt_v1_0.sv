
`timescale 1 ns / 1 ps

	module fir_filt_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 10,

		// Parameters of Axi Master Bus Interface M00_AXIS
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_START_COUNT	= 32,
		parameter integer NUM_TAPS = 5
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready,

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
		output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] accum
	);
    
    wire [31 : 0] data[0 : NUM_TAPS ];
    wire [31 : 0] accumulator [0 : NUM_TAPS ];
    wire valid [0 : NUM_TAPS ];
    wire ready [0 : NUM_TAPS ];
    
    wire [31 : 0] mult[0 : NUM_TAPS ];
    wire mult_0_out_valid;
    wire [79 : 0] mult_data_out;

    wire signed [C_S00_AXIS_TDATA_WIDTH/2 - 1 : 0] mult_real;
    wire signed [C_S00_AXIS_TDATA_WIDTH/2 - 1 : 0] mult_imag;
    
    wire fifo_s_axis_tvalid, fifo_s_axis_tready, fifo_m_axis_tready;
    wire [3 : 0] fifo_m_axis_tuser, fifo_s_axis_tuser;
    wire cmpy_ready;
    wire [NUM_TAPS : 0] mult_valid ;
    
    wire [31 : 0] fifo_data_in;
    reg init_zero_in_valid = 0;
    reg init = 1;
    
    
    assign fifo_data_in = (init) ? 32'h00000000 : s00_axis_tdata;
    
    always @(posedge s00_axi_aclk) begin
        if(s00_axis_aresetn)
            init_zero_in_valid <= 0;
        else
            if(fifo_s_axis_tready) begin
                init_zero_in_valid <= 1;
                init <= 0;    
            end
            if(init_zero_in_valid == 1)
                init_zero_in_valid <= 0;    
    end
    
    
    
 fifo_generator_0 fifo1 (
      .s_aclk(s00_axis_aclk),                // input wire s_aclk
      .s_aresetn(s00_axis_aresetn),          // input wire s_aresetn
      .s_axis_tvalid(fifo_s_axis_tvalid),  // input wire s_axis_tvalid
      .s_axis_tready(fifo_s_axis_tready),  // output wire s_axis_tready
      .s_axis_tdata(fifo_data_in),    // input wire [31 : 0] s_axis_tdata
      .s_axis_tuser(fifo_s_axis_tuser),    // input wire [3 : 0] s_axis_tuser
      .m_axis_tvalid(fifo_m_axis_tvalid),  // output wire m_axis_tvalid
      .m_axis_tready(fifo_m_axis_tready),  // input wire m_axis_tready
      .m_axis_tdata(data[0]),    // output wire [31 : 0] m_axis_tdata
      .m_axis_tuser(fifo_m_axis_tuser)    // output wire [3 : 0] m_axis_tuser
);
    assign fifo_m_axis_tready = mult_0_out_valid && ready[0];
    assign fifo_s_axis_tvalid = (init) ? init_zero_in_valid : (s00_axis_tvalid && cmpy_ready);
    assign mult_real = mult_data_out[32 : 0] >> 15;
    assign mult_imag = mult_data_out[72 : 40] >> 15;
    

    assign s00_axis_tready = (init) ? 0 : (cmpy_ready && fifo_s_axis_tready);
    assign accumulator[0] = {mult_imag, mult_real};
    assign valid[0] = mult_0_out_valid;
    
    assign m00_axis_tdata = accumulator[NUM_TAPS ];
    assign ready[NUM_TAPS ] = m00_axis_tready;
    assign m00_axis_tvalid = valid[NUM_TAPS ];

    
    fir_filt_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
		.NUM_TAPS(NUM_TAPS)
	) fir_filt_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
		.slv_reg(mult),
		.multiplier_valid(mult_valid)
	);
	
    fir_cmpy cmpy_0_inst (
        .aclk(s00_axis_aclk),                              // input wire aclk
        .aresetn(s00_axi_aresetn),
        .s_axis_a_tvalid(mult_valid[0]),                      // input wire s_axis_a_tvalid
        .s_axis_a_tready(s_axis_a_tready),        // output wire s_axis_a_tready
        .s_axis_a_tdata(mult[0]),          // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(s00_axis_tvalid && fifo_s_axis_tready),        // input wire s_axis_b_tvalid
        .s_axis_b_tready(cmpy_ready),        // output wire s_axis_b_tready
        .s_axis_b_tdata(s00_axis_tdata),
        .m_axis_dout_tvalid(mult_0_out_valid),  // output wire m_axis_dout_tvalid
        .m_axis_dout_tready(ready[0]),  // input wire m_axis_dout_tready
        .m_axis_dout_tdata(mult_data_out)    // output wire [63 : 0] m_axis_dout_tdata
    );
    
    genvar i;
    generate
        for( i = 0; i < NUM_TAPS; i = i+1) begin : generate_modules
            tap tap_inst(
                .clk(s00_axis_aclk),
                .rstn(s00_axi_aresetn),
                .data(data[i]),
                .acc_in(accumulator[i]),
                .mult(mult[i + 1]),
                .multiplier_valid(mult_valid[i + 1]),
                .acc_out(accumulator[i + 1]),
                .data_out(data[i + 1]),
                .in_valid(valid[i]),
                .out_ready(ready[i + 1]),
                .out_valid(valid[i + 1]),
                .in_ready(ready[i])
            );        
        end
    endgenerate
	endmodule
