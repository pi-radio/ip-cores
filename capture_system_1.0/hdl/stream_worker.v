`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/* -*- verilog -*- */
/*
 *  Capture System module
 *
 *  Copyright (C) 2021, pi-radio <http://pi-rad.io>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
//////////////////////////////////////////////////////////////////////////////////


module stream_worker #
    (
    
    parameter integer C_S_AXIS_TDATA_WIDTH	= 32,
    parameter integer C_M_AXIS_TDATA_WIDTH	= 32
    )
    (
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
		
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] stream_len,
		input wire len_valid,
		output wire len_ready,
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] skip_length,
		input wire skip_len_valid
    );
    
    reg [C_S_AXIS_TDATA_WIDTH-1 : 0] count_samples = 0;
    reg [C_S_AXIS_TDATA_WIDTH-1 : 0] skip_count_samples = 0;
    reg [C_S_AXIS_TDATA_WIDTH-1 : 0] length;
    reg [C_M_AXIS_TDATA_WIDTH-1 : 0] data_out;
    
    assign M_AXIS_TDATA = S_AXIS_TDATA;
    assign len_ready = ~(count_samples > 0);
    assign M_AXIS_TVALID = ~len_ready && S_AXIS_TVALID && (skip_count_samples == 0);
    assign S_AXIS_TREADY = (count_samples < stream_len) ? 
                                            M_AXIS_TREADY : 1;
    assign M_AXIS_TLAST = (count_samples == 1);
    
    always@(posedge S_AXIS_ACLK) begin
        if(~S_AXIS_ARESETN) begin
            count_samples <= 0;
            skip_count_samples <= 0;
        end
        else begin
            if(skip_len_valid && len_ready) begin
                skip_count_samples <= skip_length;
            end
            if(len_valid && len_ready) begin
                count_samples <= stream_len;
            end
            else begin
                if( M_AXIS_TREADY && S_AXIS_TVALID) begin
                    if(skip_count_samples == 0) begin
                        if(M_AXIS_TVALID) begin
                            count_samples <= count_samples - 1;
                        end
                    end
                    else begin
                        skip_count_samples <= skip_count_samples - 1;
                    end
                end
            end
        end
    end
    
endmodule
