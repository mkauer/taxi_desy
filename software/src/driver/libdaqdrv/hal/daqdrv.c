/***************************************************************************** 
 * File		  daqdrv.c
 * created on 14.07.2017
 *****************************************************************************
 * Author:	M.Eng. Dipl.-Ing(FH) Marek Penno, EL/1L23, Tel:033762/77275
 * Email:	marek.penno@desy.de
 * Mail:	DESY, Platanenallee 6, 15738 Zeuthen
 *****************************************************************************
 * Description
 * 
 * This user library does access the daqdrv kernel driver.
 *
 * The daqdrv kernel driver reads out a hardware fifo on triggered interrupt.
 * FIFO data is written into a ring buffer in kernel memory.
 * The ring buffer can be mapped into user space with mmap.
 *
 * This user library provides access to the kernel ring buffer and
 * several methods to efficiently readout and wait for new data.
 *
 ****************************************************************************/

#include <fcntl.h>
#include <unistd.h>

#include <stdint.h>

#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h> // memset definition

#include "daqdrv_defines.h"
#include "daqdrv_ioctl.h"
#include "daqdrv.h"

// Macro for debug message printing
#define DBG(MSG...) // debug messages disabled
//#define DBG(MSG...) do { printf(MSG); } while(0) // debug messages enabled

#define ERR(MSG...) do { printf(MSG); } while(0)

// structure to keep daq driver data (private)
typedef struct {
	int 				daq_handle;			// handle to the device
	size_t	 			rdOffs;				// read pointer byte offset in the ring buffer
	daqdrv_shared_data_t* data;	// shared data mapped into user space RO

	// chunks mapped from driver code into user space
	void* chunks[DAQDRV_RING_BUFFER_CHUNK_MAX_COUNT]; // its a 2d array!
} daqdrv_t;

// driver singleton instance (private)
static daqdrv_t daqdrv_instance = { 0, 0, 0, };

//-------------------------------------------------------------------------------------------------------------------------

// returns 1 if driver is open
int daqdrv_isOpen()
{
	return (daqdrv_instance.daq_handle != 0)?1:0;
}

// open the hess daq driver device and maps the ring buffer into the user space
daqdrv_error_t daqdrv_open(const char* devname)
{
	if (daqdrv_isOpen()) {
		daqdrv_close();
	}

	memset(&daqdrv_instance, 0, sizeof(daqdrv_t));
	daqdrv_error_t status = DAQDRV_ERROR_NONE;

	// open daq device
	if (!devname) devname = DAQDRV_DEVICE;

	daqdrv_instance.daq_handle = open(devname, O_RDONLY);
	if(daqdrv_instance.daq_handle == -1)
	{
		status = DAQDRV_ERROR_OPENING_DEVICE;
		goto error_open_daq;
	}

	// map shared data region
	daqdrv_instance.data = (daqdrv_shared_data_t*)mmap(NULL, sizeof(daqdrv_shared_data_t), PROT_READ, MAP_SHARED, daqdrv_instance.daq_handle, 0);
	if (daqdrv_instance.data == MAP_FAILED)
	{
		// mapping failed
		ERR("Error shared region mapping failed\n");
		status = DAQDRV_ERROR_MMAP_FAILED;
		goto error_map_daq;
	}

	if (daqdrv_instance.data->magic!=DAQDRV_MAGIC) {
		// checking magic failed...
		status = DAQDRV_ERROR_MAGIC_INVALID;
		ERR("Error magic check failed 0x%x != 0x%x\n",daqdrv_instance.data->magic, DAQDRV_MAGIC);
		goto error_check_magic;
	}

	// map ring buffer chunks

	int chunksMapped=0;

	DBG("mmap chunk size %d\n", daqdrv_instance.data->chunkSize);
	DBG("mmap chunk span %d\n", daqdrv_instance.data->mmap_chunk_span);
	DBG("mmap chunk count %d\n", daqdrv_instance.data->chunkCount);

	int i;
	for (i=0;i<daqdrv_instance.data->chunkCount;i++) {
		size_t offs=daqdrv_instance.data->mmap_chunk_span*(i+1);
		daqdrv_instance.chunks[i] = mmap(NULL, daqdrv_instance.data->chunkSize, PROT_READ, MAP_SHARED, daqdrv_instance.daq_handle, offs);

		DBG("mmap chunk %d : %p size: %d\n", i, daqdrv_instance.chunks[i], daqdrv_instance.data->chunkSize);

		if (daqdrv_instance.chunks[i] == MAP_FAILED)
		{
			// mapping failed
			ERR("Error could not map chunk #%d of %d\n",i, daqdrv_instance.data->chunkCount, DAQDRV_MAGIC);
			status = DAQDRV_ERROR_MMAP_FAILED;
			goto error_map_daq;
		}
		chunksMapped++;
	}

	// start at actual buffer write position (works like a flush)
	daqdrv_instance.rdOffs = daqdrv_instance.data->wrOffs;

	return DAQDRV_ERROR_NONE;

error_mmap_chunks:

	for (i=0;i<chunksMapped;i++) {
		munmap(daqdrv_instance.chunks[i], daqdrv_instance.data->chunkSize);
	}

error_check_magic:
	if (daqdrv_instance.data) {
		munmap(daqdrv_instance.data, sizeof(daqdrv_shared_data_t));
	}

error_map_daq:
	close(daqdrv_instance.daq_handle);

error_open_daq:
	memset(&daqdrv_instance,0,sizeof(daqdrv_t));
	return status;
}

// returns copy of the shared driver data structure
daqdrv_error_t daqdrv_getSharedInfo(daqdrv_shared_data_t* _info)
{
	if (!daqdrv_isOpen()) return DAQDRV_ERROR_DRIVER;

	memcpy(_info, daqdrv_instance.data, sizeof(daqdrv_shared_data_t) );
	return DAQDRV_ERROR_NONE;
}

// close the hess daq driver
void daqdrv_close()
{
	if (!daqdrv_isOpen()) return;

	// unmap all buffers
	int i;
	for (i=0;i<daqdrv_instance.data->chunkCount;i++) {
		if (daqdrv_instance.chunks[i]) munmap(daqdrv_instance.chunks[i], daqdrv_instance.data->chunkSize);
	}

	// unmap shared data block
	if (daqdrv_instance.data) {
		munmap(daqdrv_instance.data, sizeof(daqdrv_shared_data_t));
	}

	if (daqdrv_instance.daq_handle) {
		close(daqdrv_instance.daq_handle);
	}

	memset(&daqdrv_instance,0,sizeof(daqdrv_t));
}

// wait for a irq
daqdrv_error_t daqdrv_waitForIrq(unsigned int timeout_ms)
{
	daqdrv_ioctl_wait_for_irq_t command;
	command.timeout_ms = timeout_ms;

	int ret = ioctl(daqdrv_instance.daq_handle, DAQDRV_IOCTL_WAIT_FOR_IRQ, &command);
	if (ret == 0)
	{
		// new data is available
		return DAQDRV_ERROR_NONE;
	}
	if (errno == ETIMEDOUT || errno == -ETIMEDOUT)
	{
		return DAQDRV_ERROR_TIMEOUT;
	}

	DBG("daq driver ERROR Code returned: %d\n", errno);
	return DAQDRV_ERROR_DRIVER;
}

// Readout driver statistic information
daqdrv_error_t daqdrv_readStatistic(daqdrv_statistic_t* _statistic)
{
	int ret = ioctl(daqdrv_instance.daq_handle, DAQDRV_IOCTL_READ_STATISTIC, _statistic);
	if (ret == sizeof(daqdrv_statistic_t))
	{
		return DAQDRV_ERROR_NONE;
	}
	DBG("daqdrv_readStatistic() returned ERROR Code: %d\n", errno);
	return DAQDRV_ERROR_DRIVER;
}

// *** Read and Write Pointer Operations ***

daqdrv_error_t daqdrv_clearBuffers(void)
{
	if (!daqdrv_isOpen()) return DAQDRV_ERROR_DEVICE_NOT_OPEN;

	int ret = ioctl(daqdrv_instance.daq_handle, DAQDRV_IOCTL_CLEAR_RING_BUFFER, NULL);

	daqdrv_instance.rdOffs = daqdrv_instance.data->wrOffs;

	if (ret == 0) return DAQDRV_ERROR_NONE; else return DAQDRV_ERROR_DRIVER;
}

// returns byte offset of the write pointer offset inside of the ring buffer
size_t daqdrv_getWrOffset(void) // debug only
{
	return daqdrv_instance.data->wrOffs; // pipelining active with wrOffs2, inactive with wrOffs
}

// returns byte offset of the write pointer offset inside of the ring buffer
size_t daqdrv_getWrOffset2(void) // debug only
{
	return ioctl(daqdrv_instance.daq_handle, DAQDRV_IOCTL_GET_WR_POSITION, 0);
}

// returns byte offset of the read pointer offset inside of the ring buffer
size_t daqdrv_getRdOffset(void)
{
	return daqdrv_instance.rdOffs;
}

// returns 1, if data is available
// returns 0, otherwise
int daqdrv_isDataAvailable(void)
{
	return (daqdrv_instance.rdOffs != daqdrv_instance.data->wrOffs)?1:0;
//	return (daqdrv_instance.rdOffs != daqdrv_getWrOffset2())?1:0;
}

// returns total size of the ring buffer
size_t daqdrv_getRingBufferSize()
{
	if (!daqdrv_instance.data) return 0;
	return daqdrv_instance.data->bufferSize;
}

// returns read pointer position inside of a ring buffer chunk
void daqdrv_getRdChunkOffset(size_t* _chunkIndex, size_t* _chunkPosition)
{
	size_t rdOffs=daqdrv_instance.rdOffs;
	*_chunkIndex = rdOffs/daqdrv_instance.data->chunkSize;
	*_chunkPosition= (rdOffs%daqdrv_instance.data->chunkSize);
}

// returns write pointer position inside of a ring buffer chunk
void daqdrv_getWrChunkOffset(size_t* chunkIndex, size_t* chunkPosition)
{
	size_t pos=daqdrv_getWrOffset();
	*chunkIndex = pos/daqdrv_instance.data->chunkSize;
	*chunkPosition= (pos%daqdrv_instance.data->chunkSize);
}

// returns next 16bit word
uint16_t daqdrv_getNext16BitWord()
{
	if (!daqdrv_isDataAvailable()) return 0xaffe;

	size_t rdChunkIndex, rdChunkOffs;

	daqdrv_getRdChunkOffset(&rdChunkIndex, &rdChunkOffs);

	uint16_t *data=(uint16_t*)((char*)daqdrv_instance.chunks[rdChunkIndex] + rdChunkOffs);

	// increase read index
	daqdrv_instance.rdOffs+=2;
	if (daqdrv_instance.rdOffs>=daqdrv_instance.data->bufferSize) // wrap pointer
		daqdrv_instance.rdOffs-=daqdrv_instance.data->bufferSize;

	return *data;
}


/*
// returns read pointer address of next sample to be read (if ready to read or not)
void* daqdrv_getRdPointer(void)
{
	size_t rdOffs=daqdrv_instance.rdOffs;
	size_t chunkIndex = rdOffs/daqdrv_instance.data->chunkSize;
	size_t chunkOffset= (rdOffs%daqdrv_instance.data->chunkSize);
	return (((char*)daqdrv_instance.chunks[chunkIndex]) + chunkOffset);
}*/

// returns pointer and size to readable data in a continuous memory region for copying
// advances read pointer
// limits to _maxSize
//
// used to get data blockwise from ring buffer without copying:
// returns pointer and size to a continuous memory region of data that is ready to be read & send
// size returned is variable, but never more than min( parameter,  ring buffer chunk's size ~ 66*4096byte )
// the returned size depends on
//  - how many data is available
//  - if the data is split over several buffers (the ring buffer is split into N smaller buffer of ~280Kbyte)
//    f.ex. if 1 mbyte data is available, it will result in 4 or 5 loops over the function getnextDataBlock
//
//   buffer 1: [.............rXXXXXX]	1. call return ~100kbyte
//   buffer 2: [XXXXXXXXXXXXXXXXXXXX]   2. call return 280kbyte
//   buffer 3: [XXXXXXXXXXXXXXXXXXXX]   3. call return 280kbyte
//   buffer 4: [XXXXXXXXXXXXXXXXXXXX]   4. call return 280kbyte
//   buffer 5: [XXXXXXXXXXW.........]   5. call return ~130kbyte
//   buffer ...
//   buffer N
//
//   r - readpointer, W - write pointer , X data to be read & send, . - invalid data
size_t daqdrv_getDataEx(void** _data, size_t _maxSize)
{
	if (!daqdrv_isOpen()) return 0;
	if (!_data) return 0;

	size_t size=0;
	size_t rdChunkIndex, rdChunkOffs;
	size_t wrChunkIndex, wrChunkOffs;

	daqdrv_getRdChunkOffset(&rdChunkIndex, &rdChunkOffs);
	daqdrv_getWrChunkOffset(&wrChunkIndex, &wrChunkOffs);

	*_data=((char*)daqdrv_instance.chunks[rdChunkIndex] + rdChunkOffs);
	if (rdChunkIndex!=wrChunkIndex) {
		// chunk can be read up to its end
		size=daqdrv_instance.data->chunkSize - rdChunkOffs;
	} else {
		// read pointer and wr pointer are in the same chunk
		if (rdChunkOffs>wrChunkOffs) {
			// chunk can be read up to its end
			size=daqdrv_instance.data->chunkSize - rdChunkOffs;
		} else if (rdChunkOffs<wrChunkOffs) {
			// chunk can be read up to write pointer
			size=(wrChunkOffs - rdChunkOffs);
		} else {
			// read / write positions are same, no data available
		}
	}

	if (size>_maxSize) size=_maxSize;

	// increase read index
	daqdrv_instance.rdOffs+=size;
	if (daqdrv_instance.rdOffs>=daqdrv_instance.data->bufferSize) // wrap pointer
		daqdrv_instance.rdOffs-=daqdrv_instance.data->bufferSize;

	// return advanced number of bytes
	return size;
}

// helper to get data always as much as is theoretical possible according to the internal chunk size
size_t daqdrv_getData(void** _data)
{
	return daqdrv_getDataEx(_data, daqdrv_instance.data->chunkSize);
}
