/*****************************************************************************
* File		daqdrv.c
* created on 14.07.2017
*****************************************************************************
* Author:	M.Eng. Dipl.-Ing(FH) Marek Penno, EL/1L23, Tel:033762/77275
* Email:	marek.penno@desy.de
* Mail:		DESY, Platanenallee 6, 15738 Zeuthen
*****************************************************************************
* Description
*
* Implementation of the daqdrv user support library.
*
* Implemented as singleton. Only one device can be accessed at a time.
*
****************************************************************************/

#ifndef USER_DAQ_DRIVER_H_
#define USER_DAQ_DRIVER_H_

#include <sys/types.h>
#include <stdint.h>

#include "daqdrv_defines.h"

typedef enum {
	DAQDRV_ERROR_NONE 				= 0,
	DAQDRV_ERROR_PARAM 			 	= 1,
	DAQDRV_ERROR_OPENING_DEVICE 	= 2,
	DAQDRV_ERROR_DRIVER 			= 3,
	DAQDRV_ERROR_TIMEOUT 			= 4,
	DAQDRV_ERROR_RING_BUFFER_OVERRUN = 5,
	DAQDRV_ERROR_NO_NEW_DATA 		= 6,
	DAQDRV_ERROR_DEVICE_NOT_OPEN 	= 7,
	DAQDRV_ERROR_MMAP_FAILED 		= 8,
	DAQDRV_ERROR_MAGIC_INVALID 	= 9,
	DAQDRV_ERROR_BINARY_INCOMPATIBLE = 10,
	DAQDRV_ERROR_UNKNOWN 			= 998,
	DAQDRV_ERROR_NOT_IMPLEMENTED = 999
} daqdrv_error_t;

#define DAQDRV_DEVICE "/dev/daqdrv0"

#ifndef CEXTERN
	#ifdef __cplusplus
		#define CEXTERN extern "C"
	#else
		#define CEXTERN
	#endif
#endif

// returns 1 if driver is already open
CEXTERN int daqdrv_isOpen();

// open the daq driver device and maps the ring buffer into the user space
CEXTERN daqdrv_error_t daqdrv_open(const char* devname);

// returns copy of the shared driver data structure
CEXTERN daqdrv_error_t daqdrv_getSharedInfo(daqdrv_shared_data_t* _info);

// close the daq driver
CEXTERN void daqdrv_close();

// wait for a irq
CEXTERN daqdrv_error_t daqdrv_waitForIrq(unsigned int timeout_ms);

// Readout driver statistic information
CEXTERN daqdrv_error_t daqdrv_readStatistic(daqdrv_statistic_t* _statistic);

// *** Read and Write Pointer Operations ***

CEXTERN daqdrv_error_t daqdrv_clearBuffers(void);

// returns read pointer position of next sample to be read (if ready to read or not)
CEXTERN size_t daqdrv_getWrOffset(void);

CEXTERN size_t daqdrv_getWrOffset2(void); // debug only

// returns byte offset of the read pointer offset inside of the ring buffer
CEXTERN size_t daqdrv_getRdOffset(void);

// returns total size of the ring buffer
CEXTERN size_t daqdrv_getRingBufferSize();

// returns 1, if data is available
// returns 0, otherwise
CEXTERN int daqdrv_isDataAvailable(void);

// *** data operations ***

// returns next 16bit word
CEXTERN uint16_t daqdrv_getNext16BitWord(void);

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
CEXTERN size_t daqdrv_getDataEx(void** _data, size_t _maxSize);

CEXTERN size_t daqdrv_getData(void** _data);

// returns read pointer position inside of a ring buffer chunk
CEXTERN void daqdrv_getRdChunkOffset(size_t* _chunkIndex, size_t* _chunkPosition);

// returns write pointer position inside of a ring buffer chunk
CEXTERN void daqdrv_getWrChunkOffset(size_t* chunkIndex, size_t* chunkPosition);


#endif /* INTLK4DAQDRIVER_H_ */
