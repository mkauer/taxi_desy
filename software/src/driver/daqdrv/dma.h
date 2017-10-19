/*
 * dma.h
 *
 *  Created on: Jul 15, 2016
 *      Author: marekp
 */

#ifndef __DMAEX_DMA_H_
#define __DMAEX_DMA_H_

#include "dma_engine_extension.h"

enum {
	DMAEX_OK,
	DMAEX_ERROR,
	DMAEX_BUSY,
};

typedef struct {
	struct dma_chan*	m_pChan;

	void(*m_callback)(void*);
	void*				m_callback_param;
	int					m_nTransmitInProgress;
} dmaex_t;

// filter to find a memcpy dma channel
static bool dmaex_filter(struct dma_chan *chan, void *param)
{
	return dma_has_cap(DMA_MEMCPY, chan->device->cap_mask) ? true : false;
}

// initialize hess dma transfer
static int dmaex_initialize(dmaex_t* _data)
{
	memset(_data,0,sizeof(dmaex_t));

	dma_cap_mask_t mask;
	struct at_dma_slave* pAtSlave;

	dma_cap_zero(mask);
	dma_cap_set(DMA_MEMCPY, mask);
	// the flag DMA_PRIVATE is set to avoid sharing the dma channel with other
	// devices ex.g. network
	dma_cap_set(DMA_PRIVATE, mask);

	// search free dma channel
	_data->m_pChan = dma_request_channel(mask, dmaex_filter, NULL);

	if (!_data->m_pChan)
	{
		printk(KERN_ERR "No dma channel available!\n");
		goto err_no_dma_channel;
	}

	printk(KERN_INFO "using dma channel id: %d\n", _data->m_pChan->chan_id);

	// allocate private data at_dma_slave
	if (!_data->m_pChan->private)
	{
		pAtSlave = kzalloc(sizeof(struct at_dma_slave), GFP_KERNEL);

		if (!pAtSlave)
		{
			printk(KERN_ERR "No memory!\n");
			goto err_alloc_priv_data;
		}

		_data->m_pChan->private = pAtSlave;
	}

	// MP: not sure why the private data is allocated, i think it is not needed, have to ask davit

	// setup private structure
	pAtSlave = (struct at_dma_slave*)(_data->m_pChan->private);
	pAtSlave->dma_dev = _data->m_pChan->device->dev;
	pAtSlave->rx_reg = 0;
	pAtSlave->reg_width = AT_DMA_SLAVE_WIDTH_16BIT;
	pAtSlave->cfg = ATC_SRC_REP | ATC_DST_REP;
	pAtSlave->ctrla = ATC_SCSIZE_4 | ATC_DCSIZE_4;

	return DMAEX_OK;

err_alloc_priv_data:
	dma_release_channel(_data->m_pChan);

err_no_dma_channel:
	return DMAEX_ERROR;

}

// deinitialize dma channel data
// this function must be called before deallocation of any memory
// that could be currently written by the dma controller
static void dmaex_terminate_all(dmaex_t* _data)
{
	if (_data && _data->m_pChan) dmaengine_terminate_all(_data->m_pChan);
}

// deinitialize dma channel data
static void dmaex_deinitialize(dmaex_t* _data)
{
	// release dma channel private data
	if (_data->m_pChan && _data->m_pChan->private)
	{
		kfree(_data->m_pChan->private);
		_data->m_pChan->private = NULL;
	}

	// release dma channel
	if (_data->m_pChan) {
		dma_release_channel(_data->m_pChan);
	}
}

// returns dma channel device
struct device* dmaex_getDevice(dmaex_t* _data)
{
	// return the dma channel device
	if (_data->m_pChan)
	{
		return _data->m_pChan->device->dev;
	} else {
		return NULL;
	}
}

// call back when a dma transfer is finished
// this callback calls the user callback
static inline void dmaex_user_callback(void *_param)
{
	dmaex_t* data = (dmaex_t*)_param;

	if (data->m_nTransmitInProgress>0) data->m_nTransmitInProgress--;
	else {
		printk(KERN_ERR "data->m_nTransmitInProgress==0!\n");
	}

	if (data->m_callback) (*data->m_callback)(data->m_callback_param);
}

// starts a dma async read operation on a fifo address
//
//
static int dmaex_async_read_block(dmaex_t* _data,
	dma_addr_t a_dest, dma_addr_t a_destMin, dma_addr_t a_destMax,
	dma_addr_t a_src, size_t a_len,
	void(*_userCallback)(void*), void* _userCallbackParam)
{
	enum dma_ctrl_flags s_flags = DMA_CTRL_ACK | 				// descriptor gets free automatically after processing
								  DMA_PREP_INTERRUPT |			//
								  DMA_COMPL_SKIP_DEST_UNMAP |   // do not map destination memory address
								  DMA_COMPL_SKIP_SRC_UNMAP;		// do not map source memory address

	struct dma_async_tx_descriptor *tx;
	dma_cookie_t aCookie;

	// check, if a transfer is still in progress
	// The number of dma transmissions queued is
	// limited to 1 because the system crashes otherwise
	// when allocating descriptors while a dma transfer is still active
	//
	// This behaviour is not understood, the dma_engine should be able to
	// handle multiple queued dma jobs
	if (_data->m_nTransmitInProgress>0) return DMAEX_BUSY;

	_data->m_nTransmitInProgress++;

	// setup user callback
	_data->m_callback = _userCallback;
	_data->m_callback_param  = _userCallbackParam;

	if (unlikely(!_data->m_pChan))
	{
		printk(KERN_ERR "DMA channel = null!\n");
		return DMAEX_ERROR;
	}

	// prepare tx descriptor for transfer
	tx = atc_prep_dma_memcpyFifoBlock(_data->m_pChan, a_dest, a_destMin, a_destMax,
		a_src, a_len, s_flags);

	if (unlikely(!tx))
	{
		printk(KERN_ERR "Preparing DMA error!\n");
		return DMAEX_ERROR;
	}

	// setup callback
	tx->callback       = dmaex_user_callback;
	tx->callback_param = _data;

	// submit descriptor to dma channel work queue
	aCookie = dmaengine_submit(tx);
	if (dma_submit_error(aCookie))
	{
		//// Error handling
		printk(KERN_ERR "DMA submit error!\n");
		return DMAEX_ERROR;
	}

	// start dma transfer
	dma_async_issue_pending(_data->m_pChan);

	// ok
	return DMAEX_OK;
}

#endif /* DMA_H_ */
