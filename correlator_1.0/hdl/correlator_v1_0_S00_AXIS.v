
`timescale 1 ns / 1 ps

	module correlator_v1_0_S00_AXIS #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// AXI4Stream sink: Data Width
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_S_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line

		// AXI4Stream sink: Clock
		input wire  S_AXIS_ACLK,
		// AXI4Stream sink: Reset
		input wire  S_AXIS_ARESETN,
		// Ready to accept data in
		output wire  S_AXIS_TREADY,
		// Data in
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
		// Byte qualifier
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
		// Indicates boundary of last packet
		input wire  S_AXIS_TLAST,
		// Data is in valid
		input wire  S_AXIS_TVALID,
		
		// Ready to accept data in
		output wire  S_AXIS_CONFIG_TREADY,
		// Data in
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_CONFIG_TDATA,
		// Byte qualifier
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_CONFIG_TSTRB,
		// Indicates boundary of last packet
		input wire  S_AXIS_CONFIG_TLAST,
		// Data is in valid
		input wire  S_AXIS_CONFIG_TVALID,
		
		
		output wire  M_AXIS_TVALID,
		// TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
		// TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,
		// TLAST indicates the boundary of a packet.
		output wire  M_AXIS_TLAST,
		// TREADY indicates that the slave can accept a transfer in the current cycle.
		input wire  M_AXIS_TREADY,
		
//		output wire  M_AXIS_DATA_TVALID,
//		// TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
//		output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_DATA_TDATA,
//		// TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
//		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_DATA_TSTRB,
//		// TLAST indicates the boundary of a packet.
//		output wire  M_AXIS_DATA_TLAST,
//		// TREADY indicates that the slave can accept a transfer in the current cycle.
//		input wire  M_AXIS_DATA_TREADY,
		
		output wire [31 : 0] a,
		output wire [31 : 0] b,
		output wire [79 : 0] out
	);
	
	wire s_axis_a_tvalid;
	wire s_axis_a_tready;
	wire [31 : 0] s_axis_a_tdata;
	wire s_axis_b_tvalid;
	wire s_axis_b_tready;
	wire [31 : 0] s_axis_b_tdata;
	wire m_axis_dout_tvalid;
	wire m_axis_dout_tready;
	wire [31 : 0] m_axis_dout_tdata;
    cmpy_0 cmpy_0_inst (
        .aclk(S_AXIS_ACLK),                              // input wire aclk
        .aresetn(S_AXIS_ARESETN),
        .s_axis_a_tvalid(s_axis_a_tvalid),        // input wire s_axis_a_tvalid
        .s_axis_a_tready(s_axis_a_tready),        // output wire s_axis_a_tready
        .s_axis_a_tdata(s_axis_a_tdata),          // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(s_axis_b_tvalid),        // input wire s_axis_b_tvalid
        .s_axis_b_tready(s_axis_b_tready),        // output wire s_axis_b_tready
        .s_axis_b_tdata(s_axis_b_tdata),          // input wire [31 : 0] s_axis_b_tdata
        .m_axis_dout_tvalid(m_axis_dout_tvalid),  // output wire m_axis_dout_tvalid
        .m_axis_dout_tready(M_AXIS_TREADY),  // input wire m_axis_dout_tready
        .m_axis_dout_tdata(out)    // output wire [31 : 0] m_axis_dout_tdata
    );

    reg [C_S_AXIS_TDATA_WIDTH - 1 : 0] sync_word [0 : 1023];
    reg [10 : 0] sync_word_config_count = 0;
    reg [9 : 0] sync_word_count = 0;
    wire signed [31 : 0] tmp;
    wire signed [31 : 0] input_conj;
    
    //wire signed [C_S_AXIS_TDATA_WIDTH - 1 : 0] tmp_stored;
    
   // assign a = s_axis_a_tdata;
    assign b = s_axis_b_tdata;
   // assign out = 
    
    assign tmp = S_AXIS_TDATA[31 : 16] * (-1);
    assign input_conj[31 : 16] = tmp[15 : 0];
    assign input_conj[15 : 0] = S_AXIS_TDATA[15 : 0];
    
    assign s_axis_a_tdata = sync_word[sync_word_count];
    assign s_axis_b_tdata = input_conj;
    
    reg config_ready = 1;
    
    reg [C_S_AXIS_TDATA_WIDTH - 1 : 0] data_out;
    
    assign a = input_conj;
    assign S_AXIS_CONFIG_TREADY = config_ready;
    assign S_AXIS_TREADY = !S_AXIS_CONFIG_TREADY && s_axis_b_tready;
    assign M_AXIS_TVALID = m_axis_dout_tvalid;
    assign M_AXIS_TDATA[15 : 0] = (out[32 : 0] >> 15);
    assign M_AXIS_TDATA[31 : 16] = (out[72 : 40] >> 15);
    assign s_axis_a_tvalid = !S_AXIS_CONFIG_TREADY;// && S_AXIS_TVALID && s_axis_a_tready && s_axis_b_tready && M_AXIS_TREADY;
    assign s_axis_b_tvalid = S_AXIS_TVALID;//!S_AXIS_CONFIG_TREADY && S_AXIS_TVALID && s_axis_a_tready && s_axis_b_tready && M_AXIS_TREADY;
    
    
    
    
    always @(posedge S_AXIS_ACLK) begin
        if(!S_AXIS_ARESETN) begin
            sync_word_config_count <= 0;
            config_ready = 1;
        end
        else begin
            if(sync_word_config_count >= 1024) begin
                config_ready = 0;
            end
            if(config_ready && S_AXIS_CONFIG_TVALID) begin
                if(sync_word_config_count < 1024) begin
                    sync_word[sync_word_config_count] = S_AXIS_CONFIG_TDATA;
                    sync_word_config_count = sync_word_config_count + 1;
                end
            end
        end
    end
    
    
always @(posedge S_AXIS_ACLK) begin
    if(!S_AXIS_ARESETN) begin
        sync_word_count <= 0;
    end
    else begin
        if(s_axis_a_tvalid && s_axis_a_tready) begin//S_AXIS_TREADY && S_AXIS_TVALID && s_axis_a_tready && s_axis_b_tready && M_AXIS_TREADY) begin
            sync_word_count = sync_word_count + 1;
        end
    end
end


    
    
//    always @(posedge S_AXIS_ACLK)
//    if(!S_AXIS_ARESETN) begin
//            sync_word_count <= 0;
//        end
//        else begin
//            if(S_AXIS_TREADY && S_AXIS_TVALID && M_AXIS_TREADY) begin
//                real_tmp <= S_AXIS_TDATA[15 : 0];
//                imag_tmp <= S_AXIS_TDATA[31 : 16];
//                tmp1 <= ((real_tmp * real_tmp_stored) >> 15);// - ((imag_tmp * imag_tmp_stored) >> 15);
//                tmp2 <= ((real_tmp * imag_tmp_stored) >> 15);// + ((imag_tmp * real_tmp_stored) >> 15);
//                tmp3 <= ((imag_tmp * imag_tmp_stored) >> 15);
//                tmp4 <= ((imag_tmp * real_tmp_stored) >> 15);
//                tmp5 <= {tmp1[15], tmp1} - {tmp3[15], tmp3};
//                tmp6 <= {tmp2[15], tmp2} + {tmp4[15], tmp4};
////                data_out[15 : 0] <= tmp5;
////                data_out[31 : 16] <= tmp6;

//                data_out[15 : 0] <= ({tmp5[16], tmp5[15]} == 2'b01) ? 32'h7fff :
//                                                                ({tmp5[16], tmp5[15]} == 2'b10) ? 32'h8001  :
//                                                                tmp5[15 : 0];
                
//                data_out[31 : 16] <= ({tmp6[16], tmp6[15]} == 2'b01) ? 32'h7fff :
//                                                                ({tmp6[16], tmp6[15]} == 2'b10) ? 32'h8001  :
//                                                                tmp6[15 : 0];
//                sync_word_count <= sync_word_count + 1;
//            end
//        end

	endmodule
