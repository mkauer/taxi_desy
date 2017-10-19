/*
 * dma_engine_extension.h
 *
 *  Created on: Jul 15, 2016
 *      Author: davit Kalatarian, marekp
 *
 * This is an extension to the dma engine driver to add a new dma transfer type
 * that transfers from a fixed memory address to a memory ring buffer
 *
 * In order to modifiy the existing dma engine work queue
 * the none public methods:
 *
 *  - atc_alloc_descriptor
 *  - atc_desc_get
 *
 * had to be copied from the dma_engine original code.
 *
 */

#ifndef DMA_ENGINE_EXTENSION_H_
#define DMA_ENGINE_EXTENSION_H_

#define	ATC_DEFAULT_CFG		(ATC_FIFOCFG_HALFFIFO)
#define	ATC_DEFAULT_CTRLA	(0)
#define	ATC_DEFAULT_CTRLB	(ATC_SIF(AT_DMA_MEM_IF) \
							|ATC_DIF(AT_DMA_MEM_IF))

#define DEBUG

#include <linux/device.h>

#include <asm/dma.h>
#include <linux/dmaengine.h>
#include <linux/interrupt.h>
#include <linux/dmapool.h>
#include <../drivers/dma/at_hdmac_regs.h>
#include <mach/at_hdmac.h>


// *************** ORIGINAL CODE SNIPPETS FROM DMA ENGINE - BEGIN

/**
* atc_desc_chain - build chain adding a descripor
* @first: address of first descripor of the chain
* @prev: address of previous descripor of the chain
* @desc: descriptor to queue
*
* Called from prep_* functions
*/
static void atc_desc_chain(struct at_desc **first, struct at_desc **prev,
struct at_desc *desc)
{
	if (!(*first)) {
		*first = desc;
	}
	else {
		/* inform the HW lli about chaining */
		(*prev)->lli.dscr = desc->txd.phys;
		/* insert the link descriptor to the LD ring */
		list_add_tail(&desc->desc_node,
			&(*first)->tx_list);
	}
	*prev = desc;
}

/**
* atc_dostart - starts the DMA engine for real
* @atchan: the channel we want to start
* @first: first descriptor in the list we want to begin with
*
* Called with atchan->lock held and bh disabled
*/
static void atc_dostart(struct at_dma_chan *atchan, struct at_desc *first)
{
	struct at_dma	*atdma = to_at_dma(atchan->chan_common.device);

	/* ASSERT:  channel is idle */
	if (atc_chan_is_enabled(atchan)) {
		dev_err(chan2dev(&atchan->chan_common),
			"BUG: Attempted to start non-idle channel\n");
		dev_err(chan2dev(&atchan->chan_common),
			"  channel: s0x%x d0x%x ctrl0x%x:0x%x l0x%x\n",
			channel_readl(atchan, SADDR),
			channel_readl(atchan, DADDR),
			channel_readl(atchan, CTRLA),
			channel_readl(atchan, CTRLB),
			channel_readl(atchan, DSCR));

		/* The tasklet will hopefully advance the queue... */
		return;
	}

	vdbg_dump_regs(atchan);

	/* clear any pending interrupt */
	while (dma_readl(atdma, EBCISR))
		cpu_relax();

	channel_writel(atchan, SADDR, 0);
	channel_writel(atchan, DADDR, 0);
	channel_writel(atchan, CTRLA, 0);
	channel_writel(atchan, CTRLB, 0);
	channel_writel(atchan, DSCR, first->txd.phys);
	dma_writel(atdma, CHER, atchan->mask);

	vdbg_dump_regs(atchan);
}

/**
* atc_assign_cookie - compute and assign new cookie
* @atchan: channel we work on
* @desc: descriptor to assign cookie for
*
* Called with atchan->lock held and bh disabled
*/
static dma_cookie_t
atc_assign_cookie(struct at_dma_chan *atchan, struct at_desc *desc)
{
	dma_cookie_t cookie = atchan->chan_common.cookie;

	if (++cookie < 0)
		cookie = 1;

	atchan->chan_common.cookie = cookie;
	desc->txd.cookie = cookie;

	return cookie;
}

/**
* atc_tx_submit - set the prepared descriptor(s) to be executed by the engine
* @desc: descriptor at the head of the transaction chain
*
* Queue chain if DMA engine is working already
*
* Cookie increment and adding to active_list or queue must be atomic
*/
static dma_cookie_t atc_tx_submit(struct dma_async_tx_descriptor *tx)
{
	struct at_desc		*desc = txd_to_at_desc(tx);
	struct at_dma_chan	*atchan = to_at_dma_chan(tx->chan);
	dma_cookie_t		cookie;

	spin_lock_bh(&atchan->lock);
	cookie = atc_assign_cookie(atchan, desc);

	if (list_empty(&atchan->active_list)) {
		dev_vdbg(chan2dev(tx->chan), "tx_submit: started %u\n",
			desc->txd.cookie);
		atc_dostart(atchan, desc);
		list_add_tail(&desc->desc_node, &atchan->active_list);
	}
	else {
		dev_vdbg(chan2dev(tx->chan), "tx_submit: queued %u\n",
			desc->txd.cookie);
		list_add_tail(&desc->desc_node, &atchan->queue);
	}

	spin_unlock_bh(&atchan->lock);

	return cookie;
}

/**
* atc_alloc_descriptor - allocate and return an initialized descriptor
* @chan: the channel to allocate descriptors for
* @gfp_flags: GFP allocation flags
*
* Note: The ack-bit is positioned in the descriptor flag at creation time
*       to make initial allocation more convenient. This bit will be cleared
*       and control will be given to client at usage time (during
*       preparation functions).
*/
static struct at_desc *atc_alloc_descriptor(struct dma_chan *chan,
	gfp_t gfp_flags)
{
	struct at_desc	*desc = NULL;
	struct at_dma	*atdma = to_at_dma(chan->device);
	dma_addr_t phys;

	desc = dma_pool_alloc(atdma->dma_desc_pool, gfp_flags, &phys);
	if (desc) {
		memset(desc, 0, sizeof(struct at_desc));
		INIT_LIST_HEAD(&desc->tx_list);
		dma_async_tx_descriptor_init(&desc->txd, chan);
		/* txd.flags will be overwritten in prep functions */
		desc->txd.flags = DMA_CTRL_ACK;
		desc->txd.tx_submit = atc_tx_submit;
		desc->txd.phys = phys;
	}

	return desc;
}

/**
* atc_desc_get - get an unused descriptor from free_list
* @atchan: channel we want a new descriptor for
*/
static struct at_desc *atc_desc_get(struct at_dma_chan *atchan)
{
	struct at_desc *desc, *_desc;
	struct at_desc *ret = NULL;
	unsigned int i = 0;
	LIST_HEAD(tmp_list);

	spin_lock_bh(&atchan->lock);
	list_for_each_entry_safe(desc, _desc, &atchan->free_list, desc_node) {
		i++;
		if (async_tx_test_ack(&desc->txd)) {
			list_del(&desc->desc_node);
			ret = desc;
			break;
		}
		dev_dbg(chan2dev(&atchan->chan_common),
			"desc %p not ACKed\n", desc);
	//	printk(KERN_INFO "desc %p not ACKed\n", desc);
	}
	spin_unlock_bh(&atchan->lock);

	dev_vdbg(chan2dev(&atchan->chan_common),
		"scanned %u descriptors on freelist\n", i);

	//printk(KERN_INFO "scanned %u descriptors on freelist\n", i);

	/* no more descriptor available in initial pool: create one more */
	if (!ret) {
		printk(KERN_INFO "allocate new descriptor\n");
		ret = atc_alloc_descriptor(&atchan->chan_common, GFP_ATOMIC);
		if (ret) {
			spin_lock_bh(&atchan->lock);
			atchan->descs_allocated++;
			spin_unlock_bh(&atchan->lock);
		}
		else {
			printk(KERN_INFO "not enough descriptors available\n");

			dev_err(chan2dev(&atchan->chan_common),
				"not enough descriptors available\n");
		}
	}

	return ret;
}

/**
* atc_desc_put - move a descriptor, including any children, to the free list
* @atchan: channel we work on
* @desc: descriptor, at the head of a chain, to move to free list
*/
static void atc_desc_put(struct at_dma_chan *atchan, struct at_desc *desc)
{
	if (desc) {
		struct at_desc *child;

		spin_lock_bh(&atchan->lock);
		list_for_each_entry(child, &desc->tx_list, desc_node)
			dev_vdbg(chan2dev(&atchan->chan_common),
			"moving child desc %p to freelist\n",
			child);
		list_splice_init(&desc->tx_list, &atchan->free_list);
		dev_vdbg(chan2dev(&atchan->chan_common),
			"moving desc %p to freelist\n", desc);
		list_add(&desc->desc_node, &atchan->free_list);
		spin_unlock_bh(&atchan->lock);
	}
}

// *************** ORIGINAL CODE SNIPPETS FROM DMA ENGINE - END

/**
* Specialized dma transfer preparation for a FIFO that is accessed via the static memory controller (SMC)
*
* atc_prep_dma_memcpyFifoBlock - prepare a memcpy operation that reads from a fifo with fixed address 16bit words
*
* @chan:		the channel to prepare operation on
* @a_nDstSize:	number of DMA transactions should be performed
* @a_dest:		operation dma destination address inside of ring buffer
* @a_destMin:	begin of the destination ring buffer
* @a_destMax:	end of the destination ring buffer
* @a_src:		operation dma source fifo address
* @a_len:		operation length of the transaction
* @flags:		tx descriptor status flags
*/
static struct dma_async_tx_descriptor *
	atc_prep_dma_memcpyFifoBlock(struct dma_chan *a_chan,
	dma_addr_t a_dest, dma_addr_t a_destMin, dma_addr_t a_destMax,
	dma_addr_t a_src, size_t a_len, unsigned long a_flags)
{
	struct at_dma_chan	*atchan = to_at_dma_chan(a_chan);
	struct at_desc		*desc = NULL;
	struct at_desc		*first = NULL;
	struct at_desc		*prev = NULL;

	u32			ctrla;
	u32			ctrlb;
	dma_addr_t aDest = a_dest;

	dev_vdbg(chan2dev(a_chan), "atc_prep_dma_memcpyFifoBlock: d0x%x s0x%x l0x%zx f0x%lx\n",
		a_dest, a_src, a_len, a_flags);

//	printk(KERN_INFO "atc_prep_dma_memcpyFifoBlock: d0x%x s0x%x l0x%zx f0x%lx alloc_descr:%d\n",
//		a_dest, a_src, a_len, a_flags, atchan->descs_allocated);

	if (unlikely(!a_chan)) {
		printk(KERN_ERR "dma_chan == NULL!\n");
		return NULL;
	}

	if (unlikely(!a_len)) {
		dev_dbg(chan2dev(a_chan), "atc_prep_dma_memcpyFifoBlock: length is zero!\n");
		return NULL;
	}

	if (unlikely((a_src | aDest | a_len) & 1)) {
		dev_dbg(chan2dev(a_chan), "src, dest or len is not half word aligned!\n");
		return NULL;
	}

	ctrla = ATC_DEFAULT_CTRLA;
	ctrlb = ATC_DEFAULT_CTRLB | ATC_IEN
		| ATC_SRC_ADDR_MODE_FIXED
		| ATC_DST_ADDR_MODE_INCR
		| ATC_FC_MEM2MEM;

	// fixed to 16Bit transfers
	ctrla |= ATC_SRC_WIDTH_HALFWORD | ATC_DST_WIDTH_HALFWORD;

	size_t     wordsLeft=a_len / 2;
	dma_addr_t currentAddr=a_dest;
	int        inFirstBuffer=1;
	size_t     transferWordCount;

	//printk(KERN_ERR " dma-transfer: words: 0x%d\n", wordsLeft);

	do {
		transferWordCount=wordsLeft;

		if (inFirstBuffer) {
			// We need to check, if we hit the buffer end
			if (currentAddr + transferWordCount*2 > a_destMax) {
				// limit transfer size
				transferWordCount=(a_destMax - currentAddr) / 2;
			}
		} // else don't check buffer boundaries again, we assume, that the requested dma transfer will always be smaller than the total buffer size

		// check if transfer exceeds the dma controllers max. transfer size
		if (transferWordCount>ATC_BTSIZE_MAX) {
			transferWordCount=ATC_BTSIZE_MAX;
		}

		if (transferWordCount>0) {

			desc = atc_desc_get(atchan);
			if (!desc) {
				printk(KERN_ERR " could not allocate dma descriptor\n");
				goto err_desc_get;
			}

			// printk(KERN_ERR " currentAddr: 0x%x , len: 0x%x\n", currentAddr, transferWordCount);

			desc->lli.saddr = a_src;
			desc->lli.daddr = currentAddr;
			desc->lli.ctrla = ctrla | transferWordCount;
			desc->lli.ctrlb = ctrlb;

			desc->txd.cookie = -EBUSY;
			desc->len = transferWordCount*2;

			atc_desc_chain(&first, &prev, desc);

			wordsLeft-=transferWordCount;
			currentAddr+=transferWordCount*2;

			if (inFirstBuffer) {
				if (currentAddr  >= a_destMax) {
					inFirstBuffer=0; // disable boundary check of buffer, assuming that new chunk will always hav enough size for all words left...
					currentAddr=a_destMin;
				}
			}
		} else break;

	} while( (transferWordCount!=0) && (wordsLeft!=0));


	/* set end-of-link to the last link descriptor of list*/
	set_desc_eol(desc);

	first->txd.flags = a_flags; /* client is in control of this ack */

//	atc_desc_put(atchan, first);
//	return NULL;

	return &first->txd;

err_desc_get:
	atc_desc_put(atchan, first);
	return NULL;
}
EXPORT_SYMBOL(atc_prep_dma_memcpyFifoBlock);

/**
* Specialized dma transfer preparation for a FIFO that is accessed via the static memory controller (SMC)
*
* atc_prep_dma_memcpyFifoBlock - prepare a memcpy operation that reads from a fifo with fixed address 16bit words
*
* @chan:		the channel to prepare operation on
* @a_nDstSize:	number of DMA transactions should be performed
* @a_dest:		operation dma destination address inside of ring buffer
* @a_destMin:	begin of the destination ring buffer
* @a_destMax:	end of the destination ring buffer
* @a_src:		operation dma source fifo address
* @a_len:		operation length of the transaction
* @flags:		tx descriptor status flags
*/
static struct dma_async_tx_descriptor *
	atc_prep_dma_memcpyFifoBlock2(struct dma_chan *a_chan,
	dma_addr_t a_dest, dma_addr_t a_destMin, dma_addr_t a_destMax,
	dma_addr_t a_src, size_t a_len, unsigned long a_flags)
{
	struct at_dma_chan	*atchan = to_at_dma_chan(a_chan);
	struct at_desc		*desc = NULL;
	struct at_desc		*first = NULL;
	struct at_desc		*prev = NULL;
	size_t			xfer_count=0;
	u32			ctrla;
	u32			ctrlb;
	dma_addr_t aDest = a_dest;

	dev_vdbg(chan2dev(a_chan), "atc_prep_dma_memcpyFifoBlock: d0x%x s0x%x l0x%zx f0x%lx\n",
		a_dest, a_src, a_len, a_flags);

//	printk(KERN_INFO "atc_prep_dma_memcpyFifoBlock: d0x%x s0x%x l0x%zx f0x%lx alloc_descr:%d\n",
//		a_dest, a_src, a_len, a_flags, atchan->descs_allocated);

	if (unlikely(!a_chan)) {
		printk(KERN_ERR "dma_chan == NULL!\n");
		return NULL;
	}

	if (unlikely(!a_len)) {
		dev_dbg(chan2dev(a_chan), "atc_prep_dma_memcpyFifoBlock: length is zero!\n");
		return NULL;
	}

	if (unlikely((a_src | aDest | a_len) & 1)) {
		dev_dbg(chan2dev(a_chan), "src, dest or len is not half word aligned!\n");
		return NULL;
	}

	ctrla = ATC_DEFAULT_CTRLA;
	ctrlb = ATC_DEFAULT_CTRLB | ATC_IEN
		| ATC_SRC_ADDR_MODE_FIXED
		| ATC_DST_ADDR_MODE_INCR
		| ATC_FC_MEM2MEM;

	// fixed to 16Bit transfers
	ctrla |= ATC_SRC_WIDTH_HALFWORD | ATC_DST_WIDTH_HALFWORD;

	// check if the dma transfer crosses the end of the ring buffer
	if (a_dest + a_len > a_destMax) {
		// transfer wraps over end of ring buffer,
		// need to split the dma transfer into two transfers

		// 1st transfer

		int wordCount=(a_destMax - a_dest) / 66;
		if (wordCount>0) {

			desc = atc_desc_get(atchan);
			if (!desc) {
				printk(KERN_ERR " could not allocate 1st dma descriptor\n");
				goto err_desc_get;
			}

			xfer_count = wordCount * 66 / 2; // fixed on half word

			desc->lli.saddr = a_src;
			desc->lli.daddr = a_dest;
			desc->lli.ctrla = ctrla | xfer_count;
			desc->lli.ctrlb = ctrlb;

			desc->txd.cookie = -EBUSY;
			desc->len = xfer_count*2;

		//	printk(KERN_ALERT " two buffer 1. transfer: len%d",xfer_count);

			atc_desc_chain(&first, &prev, desc);
		} else {
			xfer_count = 0;
		}

		// 2nd transfer

		desc = atc_desc_get(atchan);
		if (!desc) {
			printk(KERN_ERR " could not allocate 2nd dma descriptor\n");
			goto err_desc_get;
		}

		xfer_count = a_len/2 - xfer_count;

		desc->lli.saddr = a_src;
		desc->lli.daddr = a_destMin;
		desc->lli.ctrla = ctrla | xfer_count;
		desc->lli.ctrlb = ctrlb;

		desc->txd.cookie = 0;
		desc->len = xfer_count*2;

	//	printk(KERN_ALERT " two buffer 2. transfer: len%d",xfer_count);

		atc_desc_chain(&first, &prev, desc);

	} else {
		// single transfer possible

		desc = atc_desc_get(atchan);
		if (!desc) {
			printk(KERN_ERR " could not allocate the dma descriptor\n");
			goto err_desc_get;
		}

		desc->lli.saddr = a_src;
		desc->lli.daddr = a_dest;
		desc->lli.ctrla = ctrla | (a_len / 2); // fixed on half word
		desc->lli.ctrlb = ctrlb;

		desc->txd.cookie = -EBUSY;
		desc->len = a_len;

	//	printk(KERN_ALERT " one buffer transfer: len%d",(a_len / 2));

		atc_desc_chain(&first, &prev, desc);
	}

	/* First descriptor of the chain embedds additional information */

//	first->txd.cookie = -EBUSY;
//	first->len = a_fifoSwitchLen;

	/* set end-of-link to the last link descriptor of list*/
	set_desc_eol(desc);

	first->txd.flags = a_flags; /* client is in control of this ack */

	return &first->txd;

err_desc_get:
	atc_desc_put(atchan, first);
	return NULL;
}
EXPORT_SYMBOL(atc_prep_dma_memcpyFifoBlock2);

#endif /* DMA_ENGINE_EXTENSION_H_ */
