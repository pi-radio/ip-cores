#include "ofdm_tx.h"
#include "xparameters.h"
//#include "xaxidma_hw.h"

#define INIT 1

#define SYMBOL_SIZE              1280
#define NUM_FRAMES               2
#define SKIP_SAMPS               (SYMBOL_SIZE * 4 + 147)
#define DATA_RX_INPUT_LEN        (NUM_FRAMES * 10 * SYMBOL_SIZE * 4 - SKIP_SAMPS * 4)
#define DATA_FIR_LOG             (NUM_FRAMES * 10 * SYMBOL_SIZE * 4)
#define DATA_EQ_LOG              (9 * 800 * 4)

#define DATA_OUT_LEN             ((9 * 100) * (NUM_FRAMES - 1))
#define DATA_LOGGED_LEN          ((10 * 100) * (NUM_FRAMES))

#define FREQ_OFFSET              0x0005


uint8_t data[DATA_OUT_LEN];
uint8_t data_log[DATA_LOGGED_LEN];
uint8_t data_fir[DATA_FIR_LOG];
uint8_t data_freq_off[DATA_FIR_LOG];
uint8_t data_equalizer[DATA_EQ_LOG];

#define FFT_SIZE                 1024
#define NUM_TAPS                 10
#define TAPS_SIZE                (NUM_TAPS * 4)
#define COMPLEX_SAMP_SIZE_BYTES  4
#define RX_PORT                  18888
#define TX_PORT                  18889
#define SYNC_UNMOD_BYTES         100
#define SYNC_MOD_BYTES           (FFT_SIZE * COMPLEX_SAMP_SIZE_BYTES)

#define SYNC_UNMOD_OFFSET        0
#define SYNC_MOD_OFFSET          SYNC_UNMOD_BYTES
#define OUTPUT_RX_OFFSET         (SYNC_UNMOD_BYTES + SYNC_MOD_BYTES)
#define LOGGER_RX_OFFSET         (OUTPUT_RX_OFFSET + DATA_OUT_LEN)
#define TAPS_OFFSET              (LOGGER_RX_OFFSET + DATA_LOGGED_LEN)
#define ZEROS_OFFSET             (TAPS_OFFSET + TAPS_SIZE)
#define CP_LEN_OFFSET            (ZEROS_OFFSET + 16)
#define LOGGER_FIR_OFFSET        (CP_LEN_OFFSET + 32)
#define LOGGER_FREQ_OFF          (LOGGER_FIR_OFFSET + DATA_FIR_LOG)
#define LOGGER_EQ_OFFSET         (LOGGER_FREQ_OFF + DATA_FIR_LOG)

uint8_t sync_tmp[SYNC_MOD_BYTES];
uint32_t taps[NUM_TAPS];

void
write_to_base(void* base, uint32_t value){
	*((volatile uint32_t*)base) = value;
}

uint32_t
read_from_base(void* base){
	return *((volatile uint32_t*) base);
}

void
map_device(void** mapped_base, int mem_desc, uint32_t addr, uint32_t map_size,
		uint32_t map_mask, uint32_t size){
	void* tmp = mmap(0, map_size, PROT_READ | PROT_WRITE, MAP_SHARED,
			mem_desc, addr & ~map_mask);
	if (tmp == (void*) -1) {
		printf("Can't map the memory to user space.\n");
		exit(0);
	}

	*mapped_base = tmp + (addr & map_mask);

	memset(*mapped_base, 0, size);

	return;
}

void reset_tx_dma_engine(void* base){
	uint32_t ResetMask = (uint32_t) XAXIDMA_CR_RESET_MASK;
	uint32_t ResetMask_tx;
	uint8_t Timeout = 10;

	write_to_base(base + XAXIDMA_TX_OFFSET +
			XAXIDMA_CR_OFFSET, ResetMask);
	do {

		ResetMask_tx = read_from_base(base + XAXIDMA_TX_OFFSET
				+ XAXIDMA_CR_OFFSET);

		if (!(ResetMask_tx & XAXIDMA_CR_RESET_MASK)) {
			break;
		}
		Timeout -= 1;
	} while (Timeout);

	if(Timeout == 0)
		printf("Engine not reset\n");

	return;
}

void reset_rx_dma_engine(void* base){
	uint32_t ResetMask = (uint32_t) XAXIDMA_CR_RESET_MASK;
	uint32_t ResetMask_rx;
	uint8_t Timeout = 10;

	write_to_base(base + XAXIDMA_RX_OFFSET +
			XAXIDMA_CR_OFFSET, ResetMask);
	do {

		ResetMask_rx = read_from_base(base + XAXIDMA_RX_OFFSET
				+ XAXIDMA_CR_OFFSET);

		if (!(ResetMask_rx & XAXIDMA_CR_RESET_MASK)) {
			break;
		}
		Timeout -= 1;
	} while (Timeout);

	if(Timeout == 0)
		printf("Engine not reset\n");

	return;
}

void config_tx_dma(void* base, uint32_t src_addr, uint32_t length){

	uint32_t Regvalue = read_from_base(base + XAXIDMA_TX_OFFSET +
			XAXIDMA_CR_OFFSET);
	Regvalue = (uint32_t)(Regvalue | XAXIDMA_CR_RUNSTOP_MASK);
	write_to_base(base + XAXIDMA_TX_OFFSET +
	XAXIDMA_CR_OFFSET,Regvalue); // Start engine

	write_to_base(base + XAXIDMA_TX_OFFSET +
	XAXIDMA_DESTADDR_OFFSET, src_addr); // Destination address
	write_to_base(base + XAXIDMA_TX_OFFSET +
		XAXIDMA_BUFFLEN_OFFSET, length);

	return;
}

void config_rx_dma(void* base, uint32_t dst_addr, uint32_t length){
	uint32_t Regvalue = read_from_base(base + XAXIDMA_RX_OFFSET +
			XAXIDMA_CR_OFFSET);
	Regvalue = (uint32_t)(Regvalue | XAXIDMA_CR_RUNSTOP_MASK);
	write_to_base(base + XAXIDMA_RX_OFFSET +
	XAXIDMA_CR_OFFSET,Regvalue); // Start engine

	write_to_base(base + XAXIDMA_RX_OFFSET +
	XAXIDMA_DESTADDR_OFFSET, dst_addr); // Destination address
	write_to_base(base + XAXIDMA_RX_OFFSET +
		XAXIDMA_BUFFLEN_OFFSET, length);
	return;
}

int main() {
	int memfd;
	void *packet_gen_base, *capt_syst_base, *ddr_rx_base, *mod_base,
	*chann_emu_base, *capt_syst_delay_base, *capt_syst_logger_base, *fir_filt_base,
	*capt_syst_fir_logger_base, *capt_syst_eq_logger_base; // AXI MM ifaces

	void *reset;

	/* AXI Stream config ifaces */
	void *dma_pl_ps_base = NULL;       // DMA PL to PS
	void *dma_ifft_tx_base = NULL;     // DMA config TX IFFT
	void *dma_ifft_rx_base = NULL;     // DMA config IFFT after correlation
	void *dma_correlator_base = NULL;  // DMA config for sync word (complex symbols) in correlator
	void *dma_pack_gen_base = NULL;    // DMA config for sync word (bit level) in packet generator
	void *dma_logger_base = NULL;      // DMA for logging output of TX modulator
	void *dma_fir_logger_base = NULL;      // DMA for logging output of FIR
	void *dma_freq_off_logger_base = NULL;      // DMA for logging output of frequency offset
	void *dma_eq_logger_base = NULL;      // DMA for logging output of equalizer


	memset(taps, 0, TAPS_SIZE);
	taps[0] = 0x00007fff;
	taps[1] = 0x00004000;
	taps[2] = 0x00000000;
	taps[3] = 0x00000000;
	taps[4] = 0x00000000;
	taps[5] = 0x00000000;
	taps[6] = 0x00000000;
	taps[7] = 0x00000000;
	taps[8] = 0x00000000;
	taps[9] = 0x00000000;
	taps[10] = 0x00000000;
	int sockfd,  sock_tx_fd, sock_tx_fd2, sock_tx_fd3;

	struct sockaddr_in servaddr, cliaddr;

	struct sockaddr_in servaddr_tx, cliaddr_tx;

	socklen_t len;
	len = sizeof(cliaddr);

	if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		perror("socket creation failed");
		exit(EXIT_FAILURE);
	}

	memset(&servaddr, 0, sizeof(servaddr));
	memset(&cliaddr, 0, sizeof(cliaddr));

//	// Filling server information
#if INIT == 0
	cliaddr.sin_family    = AF_INET; // IPv4
	cliaddr.sin_addr.s_addr = inet_addr("192.168.2.224");
	cliaddr.sin_port = htons(TX_PORT);
#endif
	servaddr.sin_family    = AF_INET; // IPv4
	servaddr.sin_addr.s_addr = INADDR_ANY;
	servaddr.sin_port = htons(RX_PORT);


	if (bind(sockfd, (const struct sockaddr *)&servaddr,
	         sizeof(servaddr)) < 0) {
		perror("bind failed");
		exit(EXIT_FAILURE);
	}

	sock_tx_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (sock_tx_fd == -1) {
        printf("TX socket creation failed...\n");
        exit(0);
    }

	sock_tx_fd2 = socket(AF_INET, SOCK_STREAM, 0);
    if (sock_tx_fd2 == -1) {
        printf("TX socket creation failed...\n");
        exit(0);
    }

	sock_tx_fd3 = socket(AF_INET, SOCK_STREAM, 0);
    if (sock_tx_fd3 == -1) {
        printf("TX socket creation failed...\n");
        exit(0);
    }

	memfd = open("/dev/mem", O_RDWR | O_SYNC);
	if (memfd == -1) {
		printf("Can't open /dev/mem.\n");
		exit(0);
	}
	map_device(&reset, memfd, 0XFF0A0054, DDR_MAP_SIZE,
			DDR_MAP_MASK, 4);

	write_to_base(reset, 0x80000000U);
	usleep(10);
	write_to_base(reset, 0x00000000U);
	usleep(10);
	write_to_base(reset, 0x80000000U);

	/* Map all devices to virtual memory address space */
	map_device(&ddr_rx_base, memfd, DDR_BASE_ADDRESS, DDR_MAP_SIZE,
			DDR_MAP_MASK, MAX_TRANSFER_LEN);
	map_device(&capt_syst_delay_base, memfd, XPAR_CAPTURE_SYSTEM_1_S00_AXI_BASEADDR, MAP_SIZE,
			MAP_MASK, 4);
#if INIT == 1
	map_device(&packet_gen_base, memfd, XPAR_PACKET_GEN_0_S00_AXI_BASEADDR, MAP_SIZE,
			MAP_MASK, 4);
	map_device(&chann_emu_base, memfd, XPAR_CHANNEL_EMULATOR_0_S00_AXI_BASEADDR, MAP_SIZE,
			MAP_MASK, 4);
	map_device(&capt_syst_base, memfd, XPAR_CAPTURE_SYSTEM_0_S00_AXI_BASEADDR, MAP_SIZE,
			MAP_MASK, 4);
	map_device(&capt_syst_fir_logger_base, memfd, XPAR_CAPTURE_SYSTEM_3_S00_AXI_BASEADDR, MAP_SIZE,
			MAP_MASK, 4);
	map_device(&capt_syst_eq_logger_base, memfd, XPAR_CAPTURE_SYSTEM_4_S00_AXI_BASEADDR, MAP_SIZE,
			MAP_MASK, 4);
	map_device(&mod_base, memfd, XPAR_MODULATOR_0_S00_AXI_BASEADDR, MAP_SIZE,
			MAP_MASK, 4);
	map_device(&capt_syst_logger_base, memfd, XPAR_CAPTURE_SYSTEM_2_S00_AXI_BASEADDR, MAP_SIZE,
				MAP_MASK, 4);
	map_device(&fir_filt_base, memfd, XPAR_FIR_FILT_0_BASEADDR, MAP_SIZE,
					MAP_MASK, 0);

#else
	map_device(&packet_gen_base, memfd, XPAR_PACKET_GEN_0_S00_AXI_BASEADDR, MAP_SIZE,
			MAP_MASK, 0);
	map_device(&capt_syst_base, memfd, XPAR_CAPTURE_SYSTEM_0_S00_AXI_BASEADDR, MAP_SIZE,
			MAP_MASK, 0);
	map_device(&mod_base, memfd, XPAR_MODULATOR_0_S00_AXI_BASEADDR, MAP_SIZE,
			MAP_MASK, 0);
	map_device(&capt_syst_logger_base, memfd, XPAR_CAPTURE_SYSTEM_2_S00_AXI_BASEADDR, MAP_SIZE,
				MAP_MASK, 0);
#endif

	map_device(&dma_pl_ps_base, memfd, XPAR_AXIDMA_0_BASEADDR, MAP_SIZE,
			MAP_MASK, 0);
	map_device(&dma_ifft_tx_base, memfd, XPAR_AXIDMA_1_BASEADDR, MAP_SIZE,
			MAP_MASK, 0);
	map_device(&dma_ifft_rx_base, memfd, XPAR_AXIDMA_2_BASEADDR, MAP_SIZE,
			MAP_MASK, 0);
	map_device(&dma_correlator_base, memfd, XPAR_AXIDMA_3_BASEADDR, MAP_SIZE,
			MAP_MASK, 0);
	map_device(&dma_pack_gen_base, memfd, XPAR_AXIDMA_4_BASEADDR, MAP_SIZE,
			MAP_MASK, 0);
	map_device(&dma_logger_base, memfd, XPAR_AXIDMA_5_BASEADDR, MAP_SIZE,
				MAP_MASK, 0);
	map_device(&dma_fir_logger_base, memfd, XPAR_AXIDMA_6_BASEADDR, MAP_SIZE,
				MAP_MASK, 0);
	map_device(&dma_freq_off_logger_base, memfd, XPAR_AXIDMA_7_BASEADDR, MAP_SIZE,
				MAP_MASK, 0);
	map_device(&dma_eq_logger_base, memfd, XPAR_AXIDMA_8_BASEADDR, MAP_SIZE,
				MAP_MASK, 0);

	/* Configure FIR filter taps */

	for(int i = 0; i<= NUM_TAPS; i++){
		write_to_base(fir_filt_base + (i * 4), taps[i]);
	}

	/* Configure the two FFT engines for inverse FFT operation*/
	memset(ddr_rx_base + CP_LEN_OFFSET, 0x0, 4);
	uint32_t test = 0x100;
	memcpy((uint8_t *)(ddr_rx_base + CP_LEN_OFFSET), &test, 4);
	reset_tx_dma_engine(dma_ifft_tx_base);
	config_tx_dma(dma_ifft_tx_base,DDR_BASE_ADDRESS + CP_LEN_OFFSET, 4);

	memset(ddr_rx_base + ZEROS_OFFSET, 0x0, 4 );
	reset_tx_dma_engine(dma_ifft_rx_base);
	config_tx_dma(dma_ifft_rx_base,DDR_BASE_ADDRESS + ZEROS_OFFSET, 4);
	uint8_t pack[SYNC_MOD_BYTES];

	/*Receive sync word unmodulated from host for packet generator config*/
#if INIT==1
	int n = recvfrom(sockfd, ddr_rx_base + SYNC_UNMOD_OFFSET, SYNC_UNMOD_BYTES,
		             0, (struct sockaddr *) &cliaddr,
		             &len);
	if(n == SYNC_UNMOD_BYTES){
		reset_tx_dma_engine(dma_pack_gen_base);
		config_tx_dma(dma_pack_gen_base, DDR_BASE_ADDRESS + SYNC_UNMOD_OFFSET,
				SYNC_UNMOD_BYTES);
	}
	else{
		printf("Wrong number of bytes for configuring packet generator\n");
		exit(0);
	}
	memset(pack, 0, SYNC_MOD_BYTES);


	/*Receive sync word modulated from host for correlator config*/

	int byte_count = 0;
	while(byte_count < SYNC_MOD_BYTES){
		n = recvfrom(sockfd, sync_tmp + byte_count, MAXBYTES,
				             0, (struct sockaddr *) &cliaddr,
				             &len);
		byte_count+= n;
	}
	if(byte_count == SYNC_MOD_BYTES){
		memcpy(ddr_rx_base + SYNC_MOD_OFFSET, sync_tmp, SYNC_MOD_BYTES);
		reset_tx_dma_engine(dma_correlator_base);
		config_tx_dma(dma_correlator_base, DDR_BASE_ADDRESS + SYNC_MOD_OFFSET,
				SYNC_MOD_BYTES);
	}
	else{
		printf("Wrong number of bytes for configuring correlator\n");
	}
	memcpy(pack, ddr_rx_base + SYNC_MOD_OFFSET, SYNC_MOD_BYTES);
#endif

	write_to_base(capt_syst_delay_base + 0x04, SKIP_SAMPS);
	write_to_base(capt_syst_delay_base, (DATA_RX_INPUT_LEN / 4));

	/* Start capture system */
	write_to_base(capt_syst_base, DATA_OUT_LEN/ 4);


	write_to_base(capt_syst_logger_base, DATA_LOGGED_LEN / 4);

	write_to_base(capt_syst_fir_logger_base, DATA_FIR_LOG / 4);

	write_to_base(capt_syst_eq_logger_base, DATA_EQ_LOG / 4);

//	/* Config logger DMAs */
	reset_rx_dma_engine(dma_logger_base);
	config_rx_dma(dma_logger_base,DDR_BASE_ADDRESS + LOGGER_RX_OFFSET, DATA_LOGGED_LEN );

	//	/* Config logger DMA */
	reset_rx_dma_engine(dma_fir_logger_base);
	config_rx_dma(dma_fir_logger_base,DDR_BASE_ADDRESS + LOGGER_FIR_OFFSET, DATA_FIR_LOG );

	reset_rx_dma_engine(dma_freq_off_logger_base);
	config_rx_dma(dma_freq_off_logger_base, DDR_BASE_ADDRESS + LOGGER_FREQ_OFF, DATA_FIR_LOG);

	reset_rx_dma_engine(dma_eq_logger_base);
	config_rx_dma(dma_eq_logger_base, DDR_BASE_ADDRESS + LOGGER_EQ_OFFSET, DATA_EQ_LOG);

	/* Config PL to PS DMA engine */
	reset_rx_dma_engine(dma_pl_ps_base);
	config_rx_dma(dma_pl_ps_base,DDR_BASE_ADDRESS + OUTPUT_RX_OFFSET, DATA_OUT_LEN);

	write_to_base(chann_emu_base, FREQ_OFFSET);

#if INIT==1
	/* Start packet generator */
	write_to_base(packet_gen_base + 0x04, 0);
	write_to_base(packet_gen_base, 1);

	//usleep(100);

#endif
	while(! (XAXIDMA_IRQ_IOC_MASK && read_from_base(dma_pl_ps_base + XAXIDMA_RX_OFFSET + XAXIDMA_SR_OFFSET))){
		// Busy wait
	}

	uint32_t txed = read_from_base(dma_pl_ps_base + XAXIDMA_RX_OFFSET +
	XAXIDMA_BUFFLEN_OFFSET);

	memcpy(data, ddr_rx_base + OUTPUT_RX_OFFSET, txed);

	uint32_t txed_log = read_from_base(dma_logger_base + XAXIDMA_RX_OFFSET +
	XAXIDMA_BUFFLEN_OFFSET);

	memcpy(data_log, ddr_rx_base + LOGGER_RX_OFFSET, txed_log);

	uint32_t correct = 0;

	uint32_t off_cnt = 0;
	for (int i = 0; i < txed; i++) {
		if (data[i] == data_log[i + 1100])
			correct++;
	}
	int success = 0;

	if (correct == txed)
		success = 1;


	uint32_t fir_log = read_from_base(dma_fir_logger_base + XAXIDMA_RX_OFFSET +
		XAXIDMA_BUFFLEN_OFFSET);

	memcpy(data_fir, ddr_rx_base + LOGGER_FIR_OFFSET, fir_log);

	uint32_t freq_off_log = read_from_base(dma_freq_off_logger_base + XAXIDMA_RX_OFFSET +
		XAXIDMA_BUFFLEN_OFFSET);

	memcpy(data_freq_off, ddr_rx_base + LOGGER_FREQ_OFF, freq_off_log);

	uint32_t eq_log = read_from_base(dma_eq_logger_base + XAXIDMA_RX_OFFSET +
		XAXIDMA_BUFFLEN_OFFSET);

	memcpy(data_equalizer, ddr_rx_base + LOGGER_EQ_OFFSET, eq_log);

	servaddr_tx.sin_family    = AF_INET; // IPv4
	servaddr_tx.sin_addr.s_addr = cliaddr.sin_addr.s_addr;
	servaddr_tx.sin_port = htons(TX_PORT);
	if (connect(sock_tx_fd, (struct sockaddr*)&servaddr_tx, sizeof(servaddr_tx)) != 0) {
	        printf("connection with the server failed...\n");
	        //exit(0);
	}


	size_t total_data =  fir_log;
	int32_t count = total_data, tosend = 1000;
	while(count >= 0){
		send(sock_tx_fd, data_fir + (total_data - count), tosend, 0);
		count -= tosend;
		if(count < tosend){
			tosend = count;
			send(sock_tx_fd, data_fir + (total_data - tosend), tosend, 0);
			break;
		}
	}
	close(sock_tx_fd);


	servaddr_tx.sin_family    = AF_INET; // IPv4
	servaddr_tx.sin_addr.s_addr = cliaddr.sin_addr.s_addr;
	servaddr_tx.sin_port = htons(TX_PORT + 1);
	if (connect(sock_tx_fd2, (struct sockaddr*)&servaddr_tx, sizeof(servaddr_tx)) != 0) {
	        printf("connection with the server failed...\n");
	        //exit(0);
	}

	 total_data =  freq_off_log;
	 count = total_data, tosend = 1000;
	while(count >= 0){
		send(sock_tx_fd2, data_freq_off + (total_data - count), tosend, 0);
		count -= tosend;
		if(count < tosend){
			tosend = count;
			send(sock_tx_fd2, data_freq_off + (total_data - tosend), tosend, 0);
			break;
		}
	}
	close(sock_tx_fd2);

	servaddr_tx.sin_family    = AF_INET; // IPv4
	servaddr_tx.sin_addr.s_addr = cliaddr.sin_addr.s_addr;
	servaddr_tx.sin_port = htons(TX_PORT + 2);
	if (connect(sock_tx_fd3, (struct sockaddr*)&servaddr_tx, sizeof(servaddr_tx)) != 0) {
	        printf("connection with the server failed...\n");
	        //exit(0);
	}

	 total_data =  eq_log;
	 count = total_data, tosend = 1000;
	while(count >= 0){
		send(sock_tx_fd3, data_equalizer + (total_data - count), tosend, 0);
		count -= tosend;
		if(count < tosend){
			tosend = count;
			send(sock_tx_fd3, data_equalizer + (total_data - tosend), tosend, 0);
			break;
		}
	}
	close(sock_tx_fd3);
}
