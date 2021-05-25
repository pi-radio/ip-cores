
`timescale 1 ns / 1 ps

	module synchronizer_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S_AXIS_CORR
		parameter integer C_S_AXIS_CORR_TDATA_WIDTH	= 64,

		// Parameters of Axi Slave Bus Interface S_AXIS_DATA_IN
		parameter integer C_S_AXIS_DATA_IN_TDATA_WIDTH	= 32,

		// Parameters of Axi Master Bus Interface M00_AXIS
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_START_COUNT	= 32,
		parameter integer threshold = 8192
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S_AXIS_CORR
		input wire  s_axis_corr_aclk,
		input wire  s_axis_corr_aresetn,
		output wire  s_axis_corr_tready,
		input wire [C_S_AXIS_CORR_TDATA_WIDTH-1 : 0] s_axis_corr_tdata,
		input wire  s_axis_corr_tlast,
		input wire  s_axis_corr_tvalid,

		// Ports of Axi Slave Bus Interface S_AXIS_DATA_IN
		input wire  s_axis_data_in_aclk,
		input wire  s_axis_data_in_aresetn,
		output wire  s_axis_data_in_tready,
		input wire [C_S_AXIS_DATA_IN_TDATA_WIDTH-1 : 0] s_axis_data_in_tdata,
		input wire [(C_S_AXIS_DATA_IN_TDATA_WIDTH/8)-1 : 0] s_axis_data_in_tstrb,
		input wire  s_axis_data_in_tlast,
		input wire  s_axis_data_in_tvalid,

		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk,
		input wire  m00_axis_aresetn,
		output wire  m00_axis_tvalid,
		output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready,
		output wire [15 : 0] mag_sq
	);
	
	assign s_axis_corr_tready = 1;
	
	wire signed [26:0] tmp_i; 
    wire signed [26:0] tmp_q;
    
    reg signed [53:0] tmp_i_sq; 
    reg signed [53:0] tmp_q_sq;
    
    assign tmp_i = s_axis_corr_tdata[26 : 0];
	assign tmp_q = s_axis_corr_tdata[58 : 32];
	
	// Calculates the magnitude squared of the input sample
	function[27 : 0] mag_squared;
	   input signed [26 : 0] i;
	   input signed [26 : 0] q;
	   begin
	       tmp_i_sq = i * i;
	       tmp_q_sq = q * q;
	       mag_squared = (tmp_i_sq >> 26) + (tmp_q_sq >> 26);
	   end
	 endfunction 
	 
	wire [26 : 0] mag_sq_sample;
	wire [26 : 0] db_sample;

    reg [2 : 0] state = 0;
    reg [2 : 0] NOISE_EST = 2'b00,
                FIRST_SEARCH = 2'b01,
                SECOND_SEARCH = 2'b10,
                THIRD_SEARCH = 2'b11,
                TXING = 3'b100;
    localparam noise_samples = 1024;
    localparam symbol_size = 1024;
    localparam cp_len = 256;
    
    reg [11 : 0] noise_samp_cnt = 0;
    reg [53 : 0] noise_accum = 0;
    reg [26 : 0] noise_floor = 0;
    
    assign mag_sq_sample = mag_squared(tmp_i, tmp_q);
    assign mag_sq = mag_sq_sample;
    
    // State variables for checking max magnitude and index
    reg [26 : 0] max_mag = 0;
    reg [15 : 0] max_index = 0;
    reg [26 : 0] max_mag2 = 0;
    reg [15 : 0] max_index2 = 0;
    reg [26 : 0] max_mag3 = 0;
    reg [15 : 0] max_index3 = 0;
    reg [9 : 0] samp_cnt = 0;
    
    // State variables to store max magnitude and index while txing
    reg [26 : 0] max_mag_txing = 0;
    reg [15 : 0] max_index_txing = 0;
    reg [9 : 0] samp_cnt_txing = 0;
    
    reg [26 : 0] max_mag_txing_stored = 0;
    reg [15 : 0] max_index_txing_stored = 0;
    
    // State variables to track in which half of the buffer we wrote last
    // 'old_which_half' stores the value of 'which_half' whenever it is 
    // changed. This gives us an indication when a full frame was received
    reg which_half = 0;
    reg old_which_half = 0;
    
    // State variable to hold the inferred start of frame
    reg [11 : 0] start_of_frame = 0;
    
    // The queue which holds two frames maximum
    reg [31 : 0] buffer [0 : 2*symbol_size];
    
    // The read and write pointers of the queue
    reg [11 : 0] buffer_write = 0; 
    wire [11 : 0] buffer_read;
    
    wire stop;
    reg wrapped = 0;
    
    reg [10 : 0] cp_rm_count = 0;
    
    wire [11 : 0] data_in_queue;
    reg [15 : 0] data_sent = 0;
    reg tx_ended = 0;
    reg tx_ended_ack1, tx_ended_ack2;
    
    // When a transmission ends (all frames have been sent to the output)
    // some procedural blocks need to be notified before the transmit circuit
    // resets its state variables. We use the 'tx_ended_ack1' and 'tx_ended_ack2'
    // registers so that these blocks can indicate when they received the 'tx_ended'
    // and the transmit circuit can then reset its state variables
    reg notify_reset = 0;
    wire reset = tx_ended_ack1 && tx_ended_ack2;
    wire tlast_recv;
    reg second_check = 0;
    reg checkpoint = 0;
    
    wire start_tx;
    
    always @(posedge s_axis_corr_aclk) begin
        if(!s_axis_corr_aresetn)
            checkpoint <= 0;
        else
            if(tx_ended)
                checkpoint <= 1;
            else
                checkpoint <= 0;
    end
    
    assign start_tx = (start_of_frame[10 : 0] == 0) ? (state == TXING) && ~checkpoint :
                                                    (state == TXING) && (data_in_queue > 0) && ~checkpoint;
    assign buffer_read = start_of_frame + data_sent;
    assign m00_axis_tvalid = (cp_rm_count >= cp_len) && start_tx;
    assign data_in_queue = (buffer_write - buffer_read) >= 2048 ? (buffer_write - buffer_read) & 11'h7ff:
                                                              buffer_write - buffer_read;
    assign m00_axis_tdata =  (start_of_frame[10 : 0] == 0) ? s_axis_data_in_tdata :
                            buffer[buffer_read[10 : 0]];
    
    assign tlast_recv = which_half != old_which_half;

    // Whenever a full frame is received we deassert data tready so that the peak detection
    // can take place. If we are in a transmit state, we only deasser the data tready signal
    // when the queue is full.
    assign stop = (((buffer_write % 1024) == 0) && (buffer_write != 0)) || wrapped;
    assign s_axis_data_in_tready = ((s_axis_corr_tvalid) && ((~stop ||  (tlast_recv)))) || 
                                    ((state == TXING) && (data_in_queue < 2*1024 - 1));

    always @ (posedge s_axis_corr_aclk) begin
        if(!s_axis_corr_aresetn) begin
            state <= 0;
            start_of_frame <= 0;
            tx_ended_ack1 <= 0;
            which_half <= 0;
            noise_floor <= 0;
        end
        else 
        if(s_axis_corr_tlast)
            which_half <= ~which_half;
        if(s_axis_corr_tlast && state != TXING) begin
        if(notify_reset)
            tx_ended_ack1 = 0;
        case(state) 
             NOISE_EST: begin
                    noise_floor <= (noise_accum) >> 10;
                    state <= FIRST_SEARCH;
             end 
             FIRST_SEARCH:
                if(max_mag > 0)
//                    if(max_index > 0)
                        state <= SECOND_SEARCH;
//                     else begin
//                        state <= TXING;
//                        start_of_frame <= which_half ? {buffer_write[11],11'h00} : {buffer_write[11], 11'h400};
//                     end
                else begin
                   if ((noise_floor + threshold < mag_sq_sample)) begin
                        state <= SECOND_SEARCH; // Edge case
                   end             
                end
                
             SECOND_SEARCH: begin
                if(wrapped || (buffer_write[11 : 8] == 4'hc))
                    start_of_frame[11] <= 1;
                 else
                    start_of_frame[11] <= 0;
                  if(max_mag2 > 0) begin
                    if(max_index == max_index2) begin
                        if (max_index == 0) begin
                            state <= TXING;
                            start_of_frame <= which_half ? {buffer_write[11],11'h00} : {buffer_write[11], 11'h400};
                        end
                        else
                            state <= THIRD_SEARCH;
                     end
                     else if (max_index_txing == max_index_txing_stored) begin
                        if (max_index_txing == 0) begin
                            state <= TXING;
                            start_of_frame <= which_half ? {buffer_write[11],11'h00} : {buffer_write[11], 11'h400};
                        end
                        else
                            state <= THIRD_SEARCH;
                     end
                     else
                        state <= FIRST_SEARCH;
                  end
                  else
                    state <= FIRST_SEARCH;
             end
             THIRD_SEARCH: begin
                if(wrapped || (buffer_write[11 : 8] == 4'hc))
                    start_of_frame[11] <= 1;
                 else
                    start_of_frame[11] <= 0;
                if(max_mag3 > 0) begin
                    if(((max_index == max_index3) && (max_index == max_index2)) || (max_index_txing == max_index3)) begin
                        state <= TXING;
                        if(max_index == 0)
                            start_of_frame <= which_half ? {buffer_write[11],11'h00} : {buffer_write[11], 11'h400};
                        else
                            start_of_frame <= which_half ? (1024 + 1024 - max_index2) & 11'h7ff :
                                                    (1024 - max_index2) & 11'h7ff;
                    end
                    else
                        state <= FIRST_SEARCH;
                 end
                 else begin
                    if(max_mag2 > 0) begin
                        if(max_index2 <= 512) begin
                            state <= TXING;
                            start_of_frame <= which_half ? (1024 - max_index2) & 11'h7ff:
                                                             (1024 + 1024 - max_index2)& 11'h7ff;
                        end
                        else begin
                            state <= TXING;
                            start_of_frame <= which_half ? (1024 + 1024 - max_index2) & 11'h7ff:
                                                                (1024 - max_index2)& 11'h7ff;
                        end
                    end
                    else if(max_mag_txing > 0) begin
                        if(max_index_txing <= 512) begin
                            state <= TXING;
                            start_of_frame <= which_half ? (1024 - max_index_txing) & 11'h7ff:
                                                             (1024 + 1024 - max_index_txing)& 11'h7ff;
                        end
                        else begin
                            state <= TXING;
                            start_of_frame <= which_half ? (1024 + 1024 - max_index_txing) & 11'h7ff:
                                                                (1024 - max_index_txing)& 11'h7ff;
                        end
                    end
                 end
               end
         endcase
         
         end
         else if (state == TXING && s_axis_corr_tlast)
            if(tx_ended) begin
                if(max_mag_txing > 0 && max_mag_txing_stored == 0) begin
                    state <= SECOND_SEARCH;
                end
                else if (max_mag_txing > 0 && max_mag_txing_stored > 0)
                    state <= THIRD_SEARCH;
                else
                   if ((noise_floor + threshold < mag_sq_sample)) begin
                        state <= SECOND_SEARCH; // Edge case
                   end
                   else  
                    state <= FIRST_SEARCH;
             tx_ended_ack1 <= 1;   
            end
            else begin
                if(max_index_txing > 0 ) begin
                    max_index_txing_stored = max_index_txing;
                    max_mag_txing_stored = max_mag_txing;
                end
            end
    end
    
    always @ (posedge s_axis_corr_aclk) begin
        if(!s_axis_corr_aresetn) begin
            noise_samp_cnt <= 0;
            samp_cnt_txing <= 0;
            tx_ended_ack2 <= 0;
            max_mag <= 0;
            max_index <= 0;
            samp_cnt <= 0;
            max_mag2 <= 0;
            max_index2 <= 0;
            max_mag3 <= 0;
            max_index3 <= 0;
            noise_accum <= 0;
            second_check <= 0;
            max_mag_txing <= 0;
            max_index_txing <= 0;
            max_mag_txing_stored <= 0;
            max_index_txing_stored <= 0;
        end
        else begin
          if(which_half != old_which_half)
            samp_cnt_txing <= 0;
          if(notify_reset) begin
            tx_ended_ack2 <= 0;
          end
          if(tx_ended) begin
              max_mag <= 0;
              max_index <= 0;
              samp_cnt <= 0;
              max_mag2 <= 0;
              max_index2 <= 0;
              max_mag3 <= 0;
              max_index3 <= 0;
              tx_ended_ack2 <= 1;   
          end
          if(s_axis_corr_tvalid) begin
            if (state == NOISE_EST) 
                    noise_accum <= noise_accum + mag_sq_sample;
            else if(state == FIRST_SEARCH) begin
                if ((noise_floor + threshold < mag_sq_sample) && (mag_sq_sample > max_mag)) begin
                    max_mag <= mag_sq_sample;
                    max_index <= samp_cnt;
                    samp_cnt <= samp_cnt + 1;
                end
                else
                   samp_cnt <= samp_cnt + 1;
            end
            else if( state == SECOND_SEARCH) begin
                second_check <= 1;
                if ((noise_floor + threshold < mag_sq_sample) && (mag_sq_sample > max_mag2)) begin
                    max_mag2 <= mag_sq_sample;
                    max_index2 <= samp_cnt;
                    samp_cnt <= samp_cnt + 1;
                end
                else
                   samp_cnt <= samp_cnt + 1;
            end
            else if(state == THIRD_SEARCH) begin
                //second_check <= 1;
                if ((noise_floor + threshold < mag_sq_sample) && (mag_sq_sample > max_mag3)) begin
                    max_mag3 <= mag_sq_sample;
                    max_index3 <= samp_cnt;
                    samp_cnt <= samp_cnt + 1;
                end
                else
                   samp_cnt <= samp_cnt + 1;
            end
            else if(state == TXING) begin
                if(second_check) begin
                    max_mag_txing <= 0;
                    max_index_txing <= 0;
                    samp_cnt_txing <= 0;
                    second_check <= 0;
                    max_mag_txing_stored <= 0;
                    max_index_txing_stored <= 0;
                end
                if ((noise_floor + threshold < mag_sq_sample) && (mag_sq_sample > max_mag_txing)) begin
                    max_mag_txing <= mag_sq_sample;
                    max_index_txing <= samp_cnt_txing;
                    samp_cnt_txing <= samp_cnt_txing + 1;
                end
                else 
                    samp_cnt_txing <= samp_cnt_txing + 1;
            end
          end // if valid
        end
    end
    
    always @(posedge s_axis_corr_aclk) begin
        if(!s_axis_corr_aresetn) begin
            old_which_half <= 0;
           // tlast_recv <= 0;
            wrapped <= 0;
            buffer_write <= 0;
        end
        else begin
           // if(state != NOISE_EST) begin
                if(old_which_half != which_half) begin
                    old_which_half <= which_half;
                 //   tlast_recv <= 1;
                end
//                if(s_axis_corr_tlast)
                    
    
                if(s_axis_data_in_tvalid && s_axis_data_in_tready) begin
            //        if(tlast_recv)
            //            tlast_recv <= 0;
                    if(wrapped)
                        wrapped <= 0;
                    if(buffer_write == 12'hfff)
                        wrapped <= 1;
                    if(state != TXING) begin
                        buffer[buffer_write[10 : 0]] <= s_axis_data_in_tdata;
                        buffer_write <= buffer_write + 1;
                    end
                    else begin
                        if(data_in_queue < (2 * 1024 - 1)) begin
                            buffer[buffer_write[10 : 0]] <= s_axis_data_in_tdata;
                            buffer_write <= buffer_write + 1;
                        end
                    end
               // end
            end
//            else begin
//                if(s_axis_data_in_tvalid && s_axis_data_in_tready) begin
//                    buffer[buffer_write[10 : 0]] <= s_axis_data_in_tdata;
//                    buffer_write <= buffer_write + 1;
//                end
//            end
        end
    end
    
    
    always @(posedge s_axis_corr_aclk) begin
     if(!s_axis_corr_aresetn) begin
        notify_reset <= 0;
        tx_ended <= 0;
        data_sent <= 0;  
        cp_rm_count <= 0;
     end
     else begin
         if(reset) begin
            notify_reset <= 1;
            tx_ended <= 0;
            data_sent <= 0;
            cp_rm_count <= 0;
         end
         if(start_tx && m00_axis_tready && !tx_ended) begin
            if(notify_reset) begin
                notify_reset <= 0;
             end
             data_sent <= data_sent + 1;
             if(cp_rm_count == 1280 - 1)
                cp_rm_count <= 0;
             else
                cp_rm_count <= cp_rm_count + 1;
             if(data_sent == 9 * 1280 - 2)
                 tx_ended <= 1;
         end
      end
    end
	endmodule
