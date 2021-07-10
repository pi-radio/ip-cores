#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <time.h>

#define XAXIDMA_TX_OFFSET	0x00000000 /**< TX channel registers base
					     *  offset */
#define XAXIDMA_RX_OFFSET	0x00000030 /**< RX channel registers base
					     * offset */

#define DDR_BASE_ADDRESS     0x10000000

#define DDR_BASE_WRITE_ADDRESS    0x80000000

/* This set of registers are applicable for both channels. Add
 * XAXIDMA_TX_OFFSET to get to TX channel, and XAXIDMA_RX_OFFSET to get to RX
 * channel
 */
#define XAXIDMA_CR_OFFSET	 0x00000000   /**< Channel control */
#define XAXIDMA_SR_OFFSET	 0x00000004   /**< Status */
#define XAXIDMA_CDESC_OFFSET	 0x00000008   /**< Current descriptor pointer */
#define XAXIDMA_CDESC_MSB_OFFSET 0x0000000C   /**< Current descriptor pointer */
#define XAXIDMA_TDESC_OFFSET	 0x00000010   /**< Tail descriptor pointer */
#define XAXIDMA_TDESC_MSB_OFFSET 0x00000014   /**< Tail descriptor pointer */
#define XAXIDMA_SRCADDR_OFFSET	 0x00000018   /**< Simple mode source address
						pointer */
#define XAXIDMA_SRCADDR_MSB_OFFSET	0x0000001C  /**< Simple mode source address
						pointer */
#define XAXIDMA_DESTADDR_OFFSET		0x00000018   /**< Simple mode destination address pointer */
#define XAXIDMA_DESTADDR_MSB_OFFSET	0x0000001C   /**< Simple mode destination address pointer */
#define XAXIDMA_BUFFLEN_OFFSET		0x00000028   /**< Tail descriptor pointer */
#define XAXIDMA_SGCTL_OFFSET		0x0000002c   /**< SG Control Register */

/** Multi-Channel DMA Descriptor Offsets **/
#define XAXIDMA_RX_CDESC0_OFFSET	0x00000040   /**< Rx Current Descriptor 0 */
#define XAXIDMA_RX_CDESC0_MSB_OFFSET	0x00000044   /**< Rx Current Descriptor 0 */
#define XAXIDMA_RX_TDESC0_OFFSET	0x00000048   /**< Rx Tail Descriptor 0 */
#define XAXIDMA_RX_TDESC0_MSB_OFFSET	0x0000004C   /**< Rx Tail Descriptor 0 */
#define XAXIDMA_RX_NDESC_OFFSET		0x00000020   /**< Rx Next Descriptor Offset */
/*@}*/

/** @name Bitmasks of XAXIDMA_CR_OFFSET register
 * @{
 */
#define XAXIDMA_CR_RUNSTOP_MASK	0x00000001 /**< Start/stop DMA channel */
#define XAXIDMA_CR_RESET_MASK	0x00000004 /**< Reset DMA engine */
#define XAXIDMA_CR_KEYHOLE_MASK	0x00000008 /**< Keyhole feature */
#define XAXIDMA_CR_CYCLIC_MASK	0x00000010 /**< Cyclic Mode */
/*@}*/

/** @name Bitmasks of XAXIDMA_SR_OFFSET register
 *
 * This register reports status of a DMA channel, including
 * run/stop/idle state, errors, and interrupts (note that interrupt
 * masks are shared with XAXIDMA_CR_OFFSET register, and are defined
 * in the _IRQ_ section.
 *
 * The interrupt coalescing threshold value and delay counter value are
 * also shared with XAXIDMA_CR_OFFSET register, and are defined in a
 * later section.
 * @{
 */
#define XAXIDMA_HALTED_MASK		0x00000001  /**< DMA channel halted */
#define XAXIDMA_IDLE_MASK		0x00000002  /**< DMA channel idle */
#define XAXIDMA_ERR_INTERNAL_MASK	0x00000010  /**< Datamover internal
						      *  err */
#define XAXIDMA_ERR_SLAVE_MASK		0x00000020  /**< Datamover slave err */
#define XAXIDMA_ERR_DECODE_MASK		0x00000040  /**< Datamover decode
						      *  err */
#define XAXIDMA_ERR_SG_INT_MASK		0x00000100  /**< SG internal err */
#define XAXIDMA_ERR_SG_SLV_MASK		0x00000200  /**< SG slave err */
#define XAXIDMA_ERR_SG_DEC_MASK		0x00000400  /**< SG decode err */
#define XAXIDMA_ERR_ALL_MASK		0x00000770  /**< All errors */

/** @name Bitmask for interrupts
 * These masks are shared by XAXIDMA_CR_OFFSET register and
 * XAXIDMA_SR_OFFSET register
 * @{
 */
#define XAXIDMA_IRQ_IOC_MASK		0x00001000 /**< Completion intr */
#define XAXIDMA_IRQ_DELAY_MASK		0x00002000 /**< Delay interrupt */
#define XAXIDMA_IRQ_ERROR_MASK		0x00004000 /**< Error interrupt */
#define XAXIDMA_IRQ_ALL_MASK		0x00007000 /**< All interrupts */
/*@}*/

#define XAXIDMA_RESET_TIMEOUT       500

#define MAP_SIZE 4096UL
#define MAP_MASK (MAP_SIZE - 1)

#define DDR_MAP_SIZE 0x10000000
#define DDR_MAP_MASK (DDR_MAP_SIZE - 1)

#define MAP_SIZE 4096UL
#define MAP_MASK (MAP_SIZE - 1)

#define DDR_WRITE_OFFSET 0x10000000

#define BUFFER_BYTESIZE		100000	// Length of the buffers for DMA transfer


#define WS_PORT     8081
#define MAXBYTES    1472

#define DMA_MAP_SIZE 0x10000000
#define BRAM_MAP_SIZE 0x10000


//
#define XAXIDMA_TRANSFER_COMPLETE      0x0000000A

#define DRAM_BASE_ADDR                 0x10000000
#define DRAM_SIZE                      128000

#define WS_PORT     8081
#define MAXBYTES    1472

#define FFT_SIZE                       1024

#define MAX_TRANSFER_LEN               100000
