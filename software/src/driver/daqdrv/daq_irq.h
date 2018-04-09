/*
 * daqfifo.h
 *
 *  Created on: Jul 15, 2016
 *      Author: marekp
 */

#ifndef DAQFIFO_H_
#define DAQFIFO_H_

#include <linux/dmaengine.h>
#include <linux/delay.h>

#include "daqdrv_defines.h"
#include "smcbus.h"

// address parameter to access the fifo
static int daqfifo_read_addr 			= 0x100;	// assumes a 16bit register, little endian
//static int daqfifo_wordcount_addr 	= 0x22; // assumes a 32bit register, bytes in fifo, little endian
static int daqfifo_clearcmd_addr 		= 0x102; // a write with any value will clear/reset the fifo
static int daqfifo_wordcount_addr 		= 0x104; // assumes a 16bit register, 9 x 16 bit words in fifo, little endian
static int daqfifo_wordsPerSlice_addr	= 0x106; // assumes a 16bit register
//static int daqfifo_sub_wordcount_addr 	= 0x28; // assumes a 4bit register, 16 bit words in fifo, little endian
static int daqfifo_irq_stall			= 0x108; // bit = 1, suppressing irq's

module_param_named(daqfifo_read_addr, daqfifo_read_addr, int, S_IRUGO | S_IWUSR);
module_param_named(daqfifo_wordcount_addr,  daqfifo_wordcount_addr,  int, S_IRUGO | S_IWUSR);
//module_param_named(daqfifo_sub_wordcount_addr,  daqfifo_sub_wordcount_addr,  int, S_IRUGO | S_IWUSR);
module_param_named(daqfifo_clearcmd_addr,  daqfifo_clearcmd_addr,  int, S_IRUGO | S_IWUSR);

//#define DAQ_RING_BUFFER_COUNT 				(50000)
//#define DAQ_RING_BUFFER_CHUNK_EVENT_COUNT	(0x10000/DAQ_SAMPLE_DATA_SIZE)
#define DAQ_RING_BUFFER_CHUNK_SIZE			(4096*64)

typedef struct {
	void* 				data;
	dma_addr_t			dma_address;
	size_t				size;
} daqfifo_chunk_t;

typedef struct
{
	rwlock_t 			accessLock;
	wait_queue_head_t 	waitQueue;

	// driver statistic data also available via debugfs
	daqdrv_statistic_t 	statistic;

	// user space shared data
	daqdrv_shared_data_t* 	shared_data;
	volatile size_t		m_dma_wrpos;
	volatile size_t		m_dma_wrpos_pipelined;

	// use space shared hess ring buffer chunks
	daqfifo_chunk_t 	m_chunks[DAQDRV_RING_BUFFER_CHUNK_MAX_COUNT];
	size_t				m_chunk_count;

	dmaex_t				m_dma;	// house keeping data for the dma channel
	struct device*		m_dma_device; // the associated kernel device object
	int 				dmaScheduleToCallback;

} daqfifo_device_t; // kernel only

// global singleton object
static daqfifo_device_t daqfifo_instance;

// allocates a dma data buffer
static int daqfifo_chunk_allocate(daqfifo_chunk_t* _chunk, size_t _size)
{
	if (!_chunk) return -1; // Parameter ERROR

	// initialize memory
	memset(_chunk,0,sizeof(daqfifo_chunk_t));

	if (s_nDMAtype==_DMA_) {
//		_chunk->data = (hess_sample_data_t*)dma_alloc_coherent(daqfifo_instance.m_dma_device, _size, &(_chunk->dma_address), GFP_KERNEL);

		// DMA
		_chunk->data = kmalloc(_size, GFP_KERNEL); // ## kmalloc can be an option too

		if (!_chunk->data) return -1; // ERROR, could no allocate

		_chunk->size = _size;

		_chunk->dma_address=dma_map_single(daqfifo_instance.m_dma_device, _chunk->data, _chunk->size, DMA_FROM_DEVICE);
		if (dma_mapping_error(daqfifo_instance.m_dma_device, _chunk->dma_address)) {
			ERR("could not do dma mapping of chunk buffer size %d\n",_chunk->size);

			kfree(_chunk->data);
			_chunk->data=0;
			return -1;
		} else {
			// INFO("successfully mapped kmalloc test buffer to dma %d\n",_chunk->dma_address);

		}

		// fill with some default data
		// INFO("chunk buffer hwaddr: 0x%x size: 0x%x\n", _chunk->dma_address, _chunk->size);

		return 0; // ok
	}
	else
	{
		// NO DMA
		_chunk->data = kmalloc(_size, GFP_KERNEL); // ## kmalloc can be an option too

		if (!_chunk->data) return -1; // ERROR, could no allocate

		_chunk->size = _size;
		// fill with some default data
		// INFO("chunk buffer size: 0x%x\n", _chunk->size);

		return 0; // ok
	}
}

// deallocates a dma data buffer
static int daqfifo_chunk_deallocate(daqfifo_chunk_t* _chunk)
{
	if (!_chunk) return -1; // Parameter ERROR

	if (!_chunk->data) return 0; // no data allocated

	if (s_nDMAtype==_DMA_) {

		// dma_free_coherent(daqfifo_instance.m_dma_device, _chunk->size, _chunk->data, _chunk->dma_address);

		dma_unmap_single(daqfifo_instance.m_dma_device, _chunk->dma_address, _chunk->size, DMA_FROM_DEVICE);

		if (_chunk->data) kfree(_chunk->data);

		memset(_chunk,0,sizeof(daqfifo_chunk_t));
		return 0; // ok
	}
	else
	{
		// NO DMA
		kfree(_chunk->data);
		memset(_chunk,0,sizeof(daqfifo_chunk_t));
		return 0; // ok
	}
}

// returns the current event count
// may be locking is not needed here
static uint32_t daqfifo_readIrqCount(void)
{
	uint32_t i;
	read_lock_irq(daqfifo_instance.accessLock);
	i = daqfifo_instance.statistic.total_irq_count;
	read_unlock_irq(daqfifo_instance.accessLock);
	return i;
}

// returns the current event count
// may be locking is not needed here
static uint32_t daqfifo_read16BitWordCount(void)
{
	uint32_t a;
	uint16_t w;
	w = smcbusrd16(daqfifo_wordsPerSlice_addr);
	a = smcbusrd16(daqfifo_wordcount_addr);
	if(w == 0xffff)
	{
		WRN("event fifo words per slice to high, assuming fpga is unconfigured or currently reconfiguring");
		return 0;
	}
	if(w == 0x0)
	{
		ERR("event fifo words per slice is 0: dma for fifo will not work");
		return 0;
	}
	if(w == 0xdead) // fallback for old firmware
	{
		return a*9;
	}
//	b=smcbusrd16(daqfifo_sub_wordcount_addr);
//	return a*((b >> 12) & 0xf) + (b & 0xf);
//	return a*9 + (b & 0xf);
	return a*w;
}

// ------------------------------------------ IRQ Handling --------------

unsigned long getTimeDiff(struct timespec* a, struct timespec* b)
{
	__kernel_time_t sec = a->tv_sec - b->tv_sec;
	return (1000000 * sec) + (a->tv_nsec - b->tv_nsec) / 1000;
}


// signals to firmware to stop further irq production
static void daqfifo_irq_begin_processing(void)
{
	daqfifo_instance.statistic.irq_last_time=daqfifo_instance.statistic.irq_start_time;
	getnstimeofday(&daqfifo_instance.statistic.irq_start_time);
	daqfifo_instance.statistic.irq_period=getTimeDiff(&daqfifo_instance.statistic.irq_start_time, &daqfifo_instance.statistic.irq_last_time);
}

static void daqfifo_irq_copy_start(void)
{
	struct timespec now;
	getnstimeofday(&now);
	daqfifo_instance.statistic.copy_start_time=now;
	daqfifo_instance.statistic.irq_duration_copy_start=getTimeDiff(&now, &daqfifo_instance.statistic.irq_start_time);
}

static void daqfifo_irq_copy_end(void)
{
	struct timespec now;
	getnstimeofday(&now);
	daqfifo_instance.statistic.irq_duration_copy=getTimeDiff(&now, &daqfifo_instance.statistic.copy_start_time);
}

// signals to firmware to continue irq production after a small deadtime
static void daqfifo_irq_end_processing(void)
{
	struct timespec now;
	getnstimeofday(&now);
	daqfifo_instance.statistic.irq_duration=getTimeDiff(&now,&daqfifo_instance.statistic.irq_start_time);
}

static void daqfifo_dma_callback(void* a_data);

// tasklet to start another dma transfer
static inline void daqfifo_start_dma(unsigned long _param)
{
	daqfifo_device_t* dev = (daqfifo_device_t*)_param;
//	uint16_t temp = 0;

	write_lock(&dev->accessLock);

	if (dev->dmaScheduleToCallback)
	{
		// if flag is still set, than we missed a dma transfer
		dev->dmaScheduleToCallback=0;
		dev->statistic.dma_errors++;
	}

	uint32_t words=daqfifo_read16BitWordCount();

	dev->statistic.fifo_count = words;

	if (words == 0x0)
	{
		smcbuswr16(daqfifo_irq_stall, 0); // enable irq's again
		dev->statistic.fifo_empty++;
		goto out;
	}

	if (words > dev->statistic.max_fifo_count)
	{
		dev->statistic.max_fifo_count = words;
	}

	// calculate buffer addresses
	int chunkIndex=dev->m_dma_wrpos / dev->shared_data->chunkSize;
	int chunkOffset=dev->m_dma_wrpos % dev->shared_data->chunkSize;
	dma_addr_t wrAddr=dev->m_chunks[chunkIndex].dma_address + chunkOffset;
	dma_addr_t endAddr=dev->m_chunks[chunkIndex].dma_address + dev->m_chunks[chunkIndex].size;
	chunkIndex++;
	if (chunkIndex>=dev->m_chunk_count) chunkIndex=0;
	dma_addr_t wrBeginNextBuffer=dev->m_chunks[chunkIndex].dma_address;

	int dma_error=0;
	int dma_words=words;
	if (dma_words>10) dma_words=10;

	dma_error=dmaex_async_read_block(&dev->m_dma,
		wrAddr,wrBeginNextBuffer,endAddr,
		smcbusstart() + daqfifo_read_addr,
		words*2, 	// byte size argument!
//		dma_words*2, 	// byte size argument!
		daqfifo_dma_callback, 0);


	// On high irq rate, long dma transfers and high system load
	// new irq might be called before the dma callback has been called,
	// also if the dma transfer itself is already finished
	// In such situations, the return value is !0 and the
	// the dma transfer submission is prosponed until the callback has been called
	// this is controlled by dmaBusy variable

	if (!dma_error) {

		// increase and wrap dma buffer write pointer
		dev->m_dma_wrpos+=words*2;
		if (dev->m_dma_wrpos>=dev->shared_data->bufferSize) dev->m_dma_wrpos-=dev->shared_data->bufferSize;

		daqfifo_irq_copy_start();

	} else {
		// set dma was busy
		// we could not commit dma
		// set flag to schedule dma transfer into dma callback
		dev->dmaScheduleToCallback = 1;

		smcbuswr16(daqfifo_irq_stall, 0); // enable irq's again
	}

out:

	daqfifo_irq_end_processing();

	write_unlock(&dev->accessLock);
}

DECLARE_TASKLET( daqfifo_start_dma_tasklet, daqfifo_start_dma,
		 (unsigned long) &daqfifo_instance );

// callback when dma transfer has finished
// - tells the firmware that fifo read out is done
// - reactivate irq's
// - updates read pointer to ring buffer
static void daqfifo_dma_callback(void* a_data)
{
	daqfifo_device_t* dev = &daqfifo_instance; //g_(daqfifo_device_t*)a_data;

	write_lock(&dev->accessLock);

	dev->statistic.fifo_count_after_copy = daqfifo_read16BitWordCount();

	daqfifo_irq_copy_end();

	if (dev->dmaScheduleToCallback) {
		// another dma transfer is already scheduled
		dev->dmaScheduleToCallback = 0;
		tasklet_hi_schedule( &daqfifo_start_dma_tasklet );
	}

#ifdef DAQ_PIPELINE_ENABLED
	dev->shared_data->wrOffs=dev->m_dma_wrpos_pipelined;
	dev->m_dma_wrpos_pipelined=dev->m_dma_wrpos;

#else // DAQ_PIPELINE_ENABLED
	dev->shared_data->wrOffs=dev->m_dma_wrpos;

#endif // DAQ_PIPELINE_ENABLED

	smcbuswr16(daqfifo_irq_stall, 0); // enable irq's again

	write_unlock(&dev->accessLock);

	wake_up(&dev->waitQueue);

}

/*
// returns the data pointer to the next data written to
static void* daqfifo_getDataPointer(size_t _index)
{
	//if (_index>=daqfifo_instance.shared_data->bufferSize) _index-=daqfifo_instance.shared_data->bufferSize;
	size_t chunkIndex=_index / daqfifo_instance.shared_data->chunkSize;
	size_t chunkOffset=_index % daqfifo_instance.shared_data->chunkSize;
	return ((char*)(daqfifo_instance.m_chunks[chunkIndex].data)) + chunkOffset;
}*/

/*
// returns the data pointer to the next data written to
static void* daqfifo_getWritePointer(void)
{
	return daqfifo_getDataPointer(daqfifo_instance.shared_data->wrOffs);
}
*/
// irq handler for dma copy
static inline irqreturn_t daqfifo_irq_handler_dma(int irq_number, void *p_dev)
{
	daqfifo_device_t* dev = (daqfifo_device_t*)p_dev;

	write_lock(&dev->accessLock);

	daqfifo_irq_begin_processing();

	dev->statistic.total_irq_count++;

	smcbuswr16(daqfifo_irq_stall, 1); // suppress further irq's

	tasklet_hi_schedule( &daqfifo_start_dma_tasklet );

	// Running the dma request in a tasklet seems to be more stable
	// Tasklet:
	// 	- the tasklet adds ~5-50us more processing time before the dma transfer starts
	//    depending how busy the system is, specially when having a lot of network load
	//  - no crashes
	// without tasklet:
	// -  less delay of starting the dma
	// -  sometime crashes with or without system hang
	//    - a crash when the firmware is loaded and a first fake interrupt is executed
	//      which should not happen because number of fifo words should be 0
	//    - a crash on higher data rates

	write_unlock(&dev->accessLock);


	return IRQ_HANDLED;
}

// irq handler for drawer and drawer interface box
static inline irqreturn_t daqfifo_irq_handler(int irq_number, void *p_dev)
{
	if (s_nDMAtype==_DMA_) {
		return daqfifo_irq_handler_dma(irq_number, p_dev);
	} else {
//		return daqfifo_irq_handler_no_dma(irq_number, p_dev);
	}

	return IRQ_HANDLED;
}

static void daqfifo_clear_ring_buffer(void)
{
	write_lock(&daqfifo_instance.accessLock);

	// free memory resources
	if (s_nDMAtype==_DMA_) {
		// stop dma channel, if still running a dma transfer
		dmaex_terminate_all(&daqfifo_instance.m_dma);
	}

	daqfifo_instance.m_dma_wrpos=0;
	daqfifo_instance.m_dma_wrpos_pipelined=0;
	daqfifo_instance.shared_data->wrOffs=0;
	daqfifo_instance.shared_data->chunkReadyIndex=0;

	// clear ring buffer chunks
	int i;
	for (i=0;i<daqfifo_instance.m_chunk_count;i++) {
		memset(daqfifo_instance.m_chunks[i].data,0x0,daqfifo_instance.m_chunks[i].size);
	}

	// clear hardware fifo
	smcbuswr16(daqfifo_clearcmd_addr, 0xff); // write something to the clear command address

	write_unlock(&daqfifo_instance.accessLock);
}

// initialize the irq and dma
static int daqfifo_initialize(void)
{
	daqfifo_device_t* dev=&daqfifo_instance;

	int irqRequestResult = -1;

	memset(dev, 0, sizeof(daqfifo_device_t));
	rwlock_init(&(dev->accessLock));
	init_waitqueue_head(&(dev->waitQueue));

	switch (s_nDMAtype)
	{
	case _NO_DMA_:
		INFO("daq mode: no dma");
		break;
	case _DMA_:
		INFO("daq mode: dma");
		break;
	default:
		ERR("dma mode not supported dma=%d",s_nDMAtype);
		return 1;
	}

	if (s_nDMAtype==_DMA_) {
		if (DMAEX_OK!=dmaex_initialize(&dev->m_dma)) {
			ERR("daq: failed to initialize dma channel");
			return 1;
		}
		dev->m_dma_device=dmaex_getDevice(&dev->m_dma);
	}

	// allocate shared buffer information
	dev->shared_data = (daqdrv_shared_data_t*)kmalloc(4096, GFP_KERNEL); // this buffer must be 1 page big to be mapped properly...
	memset(dev->shared_data, 0, sizeof(daqdrv_shared_data_t));

	INFO("Install IRQ Handler: %u bytes allocated for shared buffer\n", sizeof(daqdrv_shared_data_t));

	if (!dev->shared_data) {
		ERR("Install IRQ Handler: unable to allocate memory for daq buffer\n");
		goto err_data_alloc_shared_info;
	}

	// check dma requirements
	if (s_nDMAtype==_DMA_) {
		if (dma_set_coherent_mask(dev->m_dma_device, DMA_BIT_MASK(32))) {
			dev_warn(dev->m_dma_device, "dma: can not set coherent bitmask\n");
			return 1;
		}
	}

	// align allocated size exactly to sample size
	uint16_t w = smcbusrd16(daqfifo_wordsPerSlice_addr);
	size_t chunkSize = 0;
	size_t chunkCount = 0;
	size_t numberOfChunks = 0;

	if((dma_buffer_size_total_mb <= 0) || (dma_buffer_size_total_mb > 128))
	{
		ERR("dma_buffer_size_total_mb: invalid range! value defaults to 50MB\n");
		dma_buffer_size_total_mb = 50;
	}

	if(w == 0xffff)
	{
		chunkSize = dma_chunk_size;
		chunkCount = dma_buffer_count;
	}
	else
	{
		numberOfChunks = (1024*1024 / 4096) / (w*2); // (1MB / pageSize) / fifoWidthBytes ... will lead to slightly less than 1MB
		chunkSize = w*2 * 4096 * numberOfChunks;
		chunkCount = (1024*1024 * dma_buffer_size_total_mb) / chunkSize; // will lead to slightly more than dma_buffer_size_total_mb buffer size
	}

	if (chunkCount > DAQDRV_RING_BUFFER_CHUNK_MAX_COUNT)
	{
		INFO("requested dma buffer count to big: limited to %d", DAQDRV_RING_BUFFER_CHUNK_MAX_COUNT);
		chunkCount = DAQDRV_RING_BUFFER_CHUNK_MAX_COUNT;
	}

	dev->shared_data->chunkSize = chunkSize;

	// allocating dma buffer
	dev->m_chunk_count=0;
	int i;
	for (i=0;i<chunkCount;i++) {
		int r=daqfifo_chunk_allocate( &dev->m_chunks[i], dev->shared_data->chunkSize);
		if (!r) {
			// OK
			dev->m_chunk_count++;
		} else {
			ERR("could only allocate %d of %d requested buffer", dev->m_chunk_count, chunkCount);
			break;
		}
	}
	dev->shared_data->chunkCount=dev->m_chunk_count;
	dev->shared_data->mmap_chunk_span = ((dev->shared_data->chunkSize / PAGE_SIZE) + 1) * PAGE_SIZE;
	dev->shared_data->bufferSize=dev->m_chunk_count * dev->shared_data->chunkSize;

	// check if any chunks were allocated
	if (dev->m_chunk_count==0) {
		ERR("could not allocate any daq buffer");
		goto err_data_alloc_ring_buffer;
	}

	INFO("allocated %d daq buffer chunks of %d bytes each (%d bytes in total)\n",
			dev->m_chunk_count,
			dev->shared_data->chunkSize,
			dev->m_chunk_count * dev->shared_data->chunkSize);

	dev->shared_data->magic = DAQDRV_MAGIC;
	dev->shared_data->wrOffs = 0;

	// Activate PIOC Clock (s.441 30.3.4)
	at91_sys_write(AT91_PMC_PCER, (1 << AT91SAM9G45_ID_PIOC)); // PORT_C ID == 4

	at91_set_GPIO_periph(DAQ_IRQ_PIN, 0);
	at91_set_gpio_input(DAQ_IRQ_PIN, 0); 	// 0 == no pullup
	at91_set_deglitch(DAQ_IRQ_PIN, 1); 	// 1 == deglitch activated

	// install irq handler
	irqRequestResult = request_irq(DAQ_IRQ_PIN, daqfifo_irq_handler, IRQF_TRIGGER_FALLING | IRQF_TRIGGER_RISING, "hess_fpga", &daqfifo_instance);

	if (irqRequestResult != 0)
	{
		ERR("Install IRQ Handler: problem installing srq line irq handler %d\n", irqRequestResult);
		goto err_install_irq_handler;
	}

	return 0;

err_install_irq_handler:

	// deallocate ring buffer chunks
	for (i=0;i<daqfifo_instance.m_chunk_count;i++) {
		daqfifo_chunk_deallocate( &dev->m_chunks[i]);
	}

err_data_alloc_ring_buffer:

	// free shared memory
	kfree(daqfifo_instance.shared_data);

err_data_alloc_shared_info:

	// deinitialize dma channel
	if (s_nDMAtype==_DMA_) {
		dmaex_deinitialize(&dev->m_dma);
	}

	return 1;
}

// deinitializes irq and dma stuff
static void daqfifo_deinitialize(void)
{
	daqfifo_device_t* dev=&daqfifo_instance;

	at91_sys_write(AT91_PIOC + PIO_IDR, DAQ_IRQ_PIN_NUMBER); // PIO_IDR == interrupt disable register

	free_irq(DAQ_IRQ_PIN, dev);

	// disable irq in hardware
	// hess1u_drawer_readout_setIrqEnabled(0);

	// free memory resources
	if (s_nDMAtype==_DMA_) {
		// stop dma channel, if still running a dma transfer
		dmaex_terminate_all(&dev->m_dma);
	}

	// deallocate ring buffer chunks
	int i;
	for (i=0;i<daqfifo_instance.m_chunk_count;i++) {
		daqfifo_chunk_deallocate( &daqfifo_instance.m_chunks[i]);
	}

	// deallocate dma channel
	if (s_nDMAtype==_DMA_) {
		// free dma channel
		dmaex_deinitialize(&dev->m_dma);
	}

	// deallocate shared data
	kfree(daqfifo_instance.shared_data);
}
//-----------------------------------------------------------------------------
//--- irq end -----------------------------------------------------------------



#endif /* DAQ_IRQ_H_ */
