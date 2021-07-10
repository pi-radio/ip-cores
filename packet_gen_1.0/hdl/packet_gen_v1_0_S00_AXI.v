
`timescale 1 ns / 1 ps

	module packet_gen_v1_0_S00_AXI #
	(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH	= 10,

    parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
    parameter integer SYMBOLS = 10,
    parameter integer USED_CARRIERS = 800
)
	(
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line

    // Global Clock Signal
    input wire  S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input wire  S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    // Write channel Protection type. This signal indicates the
    // privilege and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_AWPROT,
    // Write address valid. This signal indicates that the master signaling
    // valid write address and control information.
    input wire  S_AXI_AWVALID,
    // Write address ready. This signal indicates that the slave is ready
    // to accept an address and associated control signals.
    output wire  S_AXI_AWREADY,
    // Write data (issued by master, acceped by Slave) 
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte lanes hold
    // valid data. There is one write strobe bit for each eight
    // bits of the write data bus.    
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    // Write valid. This signal indicates that valid write
    // data and strobes are available.
    input wire  S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
    // can accept the write data.
    output wire  S_AXI_WREADY,
    // Write response. This signal indicates the status
    // of the write transaction.
    output wire [1 : 0] S_AXI_BRESP,
    // Write response valid. This signal indicates that the channel
    // is signaling a valid write response.
    output wire  S_AXI_BVALID,
    // Response ready. This signal indicates that the master
    // can accept a write response.
    input wire  S_AXI_BREADY,
    // Read address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether the
    // transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_ARPROT,
    // Read address valid. This signal indicates that the channel
    // is signaling valid read address and control information.
    input wire  S_AXI_ARVALID,
    // Read address ready. This signal indicates that the slave is
    // ready to accept an address and associated control signals.
    output wire  S_AXI_ARREADY,
    // Read data (issued by slave)
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    // Read response. This signal indicates the status of the
    // read transfer.
    output wire [1 : 0] S_AXI_RRESP,
    // Read valid. This signal indicates that the channel is
    // signaling the required read data.
    output wire  S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
    input wire  S_AXI_RREADY,

    // Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
    output wire  M_AXIS_TVALID,
    // TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
    output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
    // TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
    output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,
    // TLAST indicates the boundary of a packet.
    output wire  M_AXIS_TLAST,
    // TREADY indicates that the slave can accept a transfer in the current cycle.
    input wire  M_AXIS_TREADY,
    output wire  S_AXIS_CONFIG_TREADY,
    // Data in
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXIS_CONFIG_TDATA,
    // Byte qualifier
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXIS_CONFIG_TSTRB,
    // Indicates boundary of last packet
    input wire  S_AXIS_CONFIG_TLAST,
    // Data is in valid
    input wire  S_AXIS_CONFIG_TVALID
);

    // AXI4LITE signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
    reg  	axi_awready;
    reg  	axi_wready;
    reg [1 : 0] 	axi_bresp;
    reg  	axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
    reg  	axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
    reg [1 : 0] 	axi_rresp;
    reg  	axi_rvalid;


    // Example-specific design signals
    // local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
    // ADDR_LSB is used for addressing 32/64 bit registers/memories
    // ADDR_LSB = 2 for 32 bits (n downto 2)
    // ADDR_LSB = 3 for 64 bits (n downto 3)
    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 7;
    //----------------------------------------------
    //-- Signals for user logic register space example
    //------------------------------------------------
    //-- Number of Slave Registers 256
    reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg[0 : 1];

    wire	 slv_reg_rden;
    wire	 slv_reg_wren;
    reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
    integer	 byte_index;
    integer	 reg_index;
    reg	 aw_en;
    reg  [C_S_AXI_DATA_WIDTH-1:0] bit_counter;
    reg  [7:0] position_index = 1;
    reg  [C_M_AXIS_TDATA_WIDTH - 1 : 0] data_out;
    reg  [1023 : 0] pilot_mask = 0;
    reg  [31 : 0] index;
    reg  [31 : 0] m_index;
    reg [9 : 0] subc_cnt = 0;
    reg [9 : 0] symbol_cnt = 0;

    reg [10 : 0] sync_word_count = 0;


    reg [9:0] num_samples = 0;
    reg mvalid = 0;
    reg dummy;

    reg [799 : 0] sync_word;

    reg [31 : 0] seed = 32'hb5a328f4;

    reg start_count = 0;
    reg start_indef_count = 0;
    reg [31 : 0] sample_cnt = 0;

    // I/O Connections assignments

    assign M_AXIS_TDATA    = data_out;
    assign M_AXIS_TVALID   = mvalid;
    assign M_AXIS_TLAST    = (symbol_cnt == (SYMBOLS - 1)) && (subc_cnt == (USED_CARRIERS));
    assign S_AXI_AWREADY	= axi_awready;
    assign S_AXI_WREADY	= axi_wready;
    assign S_AXI_BRESP	= axi_bresp;
    assign S_AXI_BVALID	= axi_bvalid;
    assign S_AXI_ARREADY	= axi_arready;
    assign S_AXI_RDATA	= axi_rdata;
    assign S_AXI_RRESP	= axi_rresp;
    assign S_AXI_RVALID	= axi_rvalid;

    assign S_AXIS_CONFIG_TREADY = (sync_word_count < USED_CARRIERS);
    // Implement axi_awready generation
    // axi_awready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
    // de-asserted when reset is low.

    always @(posedge S_AXI_ACLK) begin
        if(S_AXI_ARESETN == 1'b0)
            sample_cnt <= 0;
        else begin
            if(start_count)
                sample_cnt <= slv_reg[1];
            if(M_AXIS_TREADY && sample_cnt > 0)
                sample_cnt <= sample_cnt - 1;
        end
    end


    always @(posedge S_AXI_ACLK) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            sync_word_count <= 0;
        end
        else begin
            if(S_AXIS_CONFIG_TVALID && S_AXIS_CONFIG_TREADY) begin
                sync_word[sync_word_count +: C_S_AXI_DATA_WIDTH] = S_AXIS_CONFIG_TDATA;
                sync_word_count = sync_word_count + C_S_AXI_DATA_WIDTH;
            end
        end
    end

    always@(posedge S_AXI_ACLK) begin
        if(M_AXIS_TREADY) begin
            if(slv_reg[0] > 0 && (start_indef_count || (sample_cnt > 0))) begin
                mvalid = 1;
                if(subc_cnt >= USED_CARRIERS) begin
                    subc_cnt = 0;
                    symbol_cnt = symbol_cnt + 1;
                    if(symbol_cnt >= SYMBOLS)
                        symbol_cnt = 0;
                end
                if(symbol_cnt == 0) begin
                    data_out = sync_word[subc_cnt +: C_M_AXIS_TDATA_WIDTH];
                end
                else begin
                    data_out = (seed * subc_cnt) + symbol_cnt;
                    for (index = 0 ; index < C_M_AXIS_TDATA_WIDTH; index = index + 1) begin
                        if((subc_cnt + index) % 10 == 0)
                            data_out[index] = 1;
                        else if((subc_cnt + index) % 10 == 5)
                            data_out[index] = 0;
                    end
                end
                subc_cnt = subc_cnt + C_M_AXIS_TDATA_WIDTH;
            end
            else begin
                mvalid <= 0;
                subc_cnt <= 0;
                symbol_cnt <= 0;
            end
        end
    end


    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            begin
                axi_awready <= 1'b0;
                aw_en <= 1'b1;
            end
        else
            begin
                if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
                    begin
                        // slave is ready to accept write address when 
                        // there is a valid write address and write data
                        // on the write address and data bus. This design 
                        // expects no outstanding transactions. 
                        axi_awready <= 1'b1;
                        aw_en <= 1'b0;
                    end
                else if (S_AXI_BREADY && axi_bvalid)
                    begin
                        aw_en <= 1'b1;
                        axi_awready <= 1'b0;
                    end
                else
                    begin
                        axi_awready <= 1'b0;
                    end
            end
    end

    // Implement axi_awaddr latching
    // This process is used to latch the address when both 
    // S_AXI_AWVALID and S_AXI_WVALID are valid. 

    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            begin
                axi_awaddr <= 0;
            end
        else
            begin
                if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
                begin
                    // Write Address latching 
                    axi_awaddr <= S_AXI_AWADDR;
                end
            end
    end

    // Implement axi_wready generation
    // axi_wready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
    // de-asserted when reset is low. 

    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            begin
                axi_wready <= 1'b0;
            end
        else
            begin
                if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
                    begin
                        // slave is ready to accept write data when 
                        // there is a valid write address and write data
                        // on the write address and data bus. This design 
                        // expects no outstanding transactions. 
                        axi_wready <= 1'b1;
                    end
                else
                    begin
                        axi_wready <= 1'b0;
                    end
            end
    end

    // Implement memory mapped register select and write logic generation
    // The write data is accepted and written to memory mapped registers when
    // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
    // select byte enables of slave registers while writing.
    // These registers are cleared when reset (active low) is applied.
    // Slave register write enable is asserted when valid address and data are available
    // and the slave is ready to accept the write address and write data.
    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            begin
                for ( reg_index = 0; reg_index <= 1 ; reg_index = reg_index+1 ) begin
                    slv_reg[reg_index] <= 0;
                end
                start_indef_count <= 0;
                start_count <= 0;
            end
        else begin
            if(start_count)
                start_count <= 0;
            if (slv_reg_wren) begin
                slv_reg[axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]] <= S_AXI_WDATA;
                if(axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0 && S_AXI_WDATA == 0)
                    start_indef_count <= 0;
                else if(axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0 && S_AXI_WDATA == 1 && slv_reg[1] == 0)
                    start_indef_count <= 1;
                else if(axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0 && S_AXI_WDATA == 1 && slv_reg[1] > 0)
                    start_count <= 1;
            end
        end
    end

    // Implement write response logic generation
    // The write response and response valid signals are asserted by the slave 
    // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
    // This marks the acceptance of address and indicates the status of 
    // write transaction.

    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            begin
                axi_bvalid  <= 0;
                axi_bresp   <= 2'b0;
            end
        else
            begin
                if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
                    begin
                        // indicates a valid write response is available
                        axi_bvalid <= 1'b1;
                        axi_bresp  <= 2'b0; // 'OKAY' response 
                    end // work error responses in future
                else
                    begin
                        if (S_AXI_BREADY && axi_bvalid)
                        //check if bready is asserted while bvalid is high) 
                        //(there is a possibility that bready is always asserted high)   
                        begin
                            axi_bvalid <= 1'b0;
                        end
                    end
            end
    end

    // Implement axi_arready generation
    // axi_arready is asserted for one S_AXI_ACLK clock cycle when
    // S_AXI_ARVALID is asserted. axi_awready is 
    // de-asserted when reset (active low) is asserted. 
    // The read address is also latched when S_AXI_ARVALID is 
    // asserted. axi_araddr is reset to zero on reset assertion.

    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            begin
                axi_arready <= 1'b0;
                axi_araddr  <= 32'b0;
            end
        else
            begin
                if (~axi_arready && S_AXI_ARVALID)
                    begin
                        // indicates that the slave has acceped the valid read address
                        axi_arready <= 1'b1;
                        // Read address latching
                        axi_araddr  <= S_AXI_ARADDR;
                    end
                else
                    begin
                        axi_arready <= 1'b0;
                    end
            end
    end

    // Implement axi_arvalid generation
    // axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
    // S_AXI_ARVALID and axi_arready are asserted. The slave registers 
    // data are available on the axi_rdata bus at this instance. The 
    // assertion of axi_rvalid marks the validity of read data on the 
    // bus and axi_rresp indicates the status of read transaction.axi_rvalid 
    // is deasserted on reset (active low). axi_rresp and axi_rdata are 
    // cleared to zero on reset (active low).  
    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            begin
                axi_rvalid <= 0;
                axi_rresp  <= 0;
            end
        else
            begin
                if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
                    begin
                        // Valid read data is available at the read data bus
                        axi_rvalid <= 1'b1;
                        axi_rresp  <= 2'b0; // 'OKAY' response
                    end
                else if (axi_rvalid && S_AXI_RREADY)
                begin
                    // Read data is accepted by the master
                    axi_rvalid <= 1'b0;
                end
            end
    end

    // Implement memory mapped register select and read logic generation
    // Slave register read enable is asserted when valid address is available
    // and the slave is ready to accept the read address.
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
    always @(*)
    begin
        reg_data_out = slv_reg[axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]];
        // Address decoding for reading registers

    end

    // Output register or memory read data
    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            begin
                axi_rdata  <= 0;
            end
        else
            begin
                // When there is a valid read address (S_AXI_ARVALID) with 
                // acceptance of read address by the slave (axi_arready), 
                // output the read dada 
                if (slv_reg_rden)
                begin
                    axi_rdata <= reg_data_out; // register read data
                end
            end
    end

    // Add user logic here

    // User logic ends

endmodule
