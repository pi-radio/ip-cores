`timescale 1ns / 1ps


module data_module #
        (
        parameter integer SYMBOLS_PER_FRAME = 10,
        parameter integer USED_CARRIERS = 800,
        parameter integer PILOT_DENSITY = 5,
        parameter integer C_M_AXIS_TDATA_WIDTH = 40
        )
        (
    	input wire  s_axis_data_aclk,
		input wire  s_axis_data_aresetn,
		output wire  s_axis_data_tready,
		input wire [C_S_AXIS_DATA_TDATA_WIDTH-1 : 0] s_axis_data_tdata,
		input wire [(C_S_AXIS_DATA_TDATA_WIDTH/8)-1 : 0] s_axis_data_tstrb,
		input wire  s_axis_data_tlast,
		input wire  s_axis_data_tvalid,
        input wire [799 : 0] sync_word,
        input wire  m_axis_data_aclk,
		input wire  m_axis_data_aresetn,
		output wire  m_axis_data_tvalid,
		output wire [C_M_AXIS_DATA_TDATA_WIDTH-1 : 0] m_axis_data_tdata,
		output wire [(C_M_AXIS_DATA_TDATA_WIDTH/8)-1 : 0] m_axis_data_tstrb,
		output wire  m_axis_data_tlast,
		input wire  m_axis_data_tready
    );
    reg [9 : 0] subc_cnt = 0;
    reg [9 : 0] symbol_cnt = 0;
    reg [39 : 0] data_out;
    reg initial_setup = 1;
    
    reg[5 : 0] bit_index;
    
    assign m_axis_data_tdata[4 : 1] = s_axis_data_tdata[3 : 0];
    assign m_axis_data_tdata[9 : 6] = s_axis_data_tdata[7 : 4];
    assign m_axis_data_tdata[14 : 11] = s_axis_data_tdata[11 : 8];
    assign m_axis_data_tdata[19 : 16] = s_axis_data_tdata[15 : 12];
    assign m_axis_data_tdata[24 : 21] = s_axis_data_tdata[19 : 16];
    assign m_axis_data_tdata[29 : 26] = s_axis_data_tdata[23 : 20];
    assign m_axis_data_tdata[34 : 31] = s_axis_data_tdata[27 : 24];
    assign m_axis_data_tdata[39 : 36] = s_axis_data_tdata[31 : 28];
    
    always@(posedge s_axis_data_aclk) begin
        if(!s_axis_data_aresetn)
            initial_setup <= 1;
        else
            if(initial_setup) begin
                for(bit_index=0; bit_index < C_M_AXIS_TDATA_WIDTH; bit_index=bit_index + PILOT_DENSITY) begin
                    if(bit_index % (2 * PILOT_DENSITY) == 0)
                        data_out[bit_index] <= 1;
                    else if(bit_index % (2 * PILOT_DENSITY) == PILOT_DENSITY)
                        data_out[bit_index] <= 0;
                end
            end
    end
    
     always@(posedge s_axis_data_aclk) begin
        if(!s_axis_data_aresetn)
            symbol_cnt <= 0;
        else begin
            if((subc_cnt == USED_CARRIERS - 1) && s_axis_data_tready && s_axis_data_tvalid)
                if(symbol_cnt < SYMBOLS_PER_FRAME - 1)
                    symbol_cnt <= symbol_cnt + 1;
                else
                    symbol_cnt <= 0;
        end
     end
    
    
endmodule
