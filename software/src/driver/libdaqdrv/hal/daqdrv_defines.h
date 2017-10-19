/*****************************************************************************
* File		daqdrv_defines.h
* created on 14.07.2017
*****************************************************************************
* Author:	M.Eng. Dipl.-Ing(FH) Marek Penno, EL/1L23, Tel:033762/77275
* Email:	marek.penno@desy.de
* Mail:		DESY, Platanenallee 6, 15738 Zeuthen
*****************************************************************************
* Description
*
* structure definition exchanged between daqdrv kernel driver and user
* support library.
*
* Shared between kernel driver and user support library
*
****************************************************************************/

#ifndef DAQDRV_DEFINES_H_
#define DAQDRV_DEFINES_H_

#define DAQDRV_RING_BUFFER_CHUNK_MAX_COUNT	1000
#define DAQDRV_MAGIC 						0xcafeaffe

typedef struct
{
//	int daq_errors;

	long diff_us;
	long triggerRate;
	//	uint32_t irq_counts;
//	uint32_t sync_lost;

	// no-dma specific data
	uint32_t eventcounter_mismatch;
	uint32_t eventcounter_mismatch_old;
	uint32_t eventcounter_mismatch_new;
	uint32_t eventcounter;
	uint32_t samples_0;
	uint32_t samples_16;
	uint32_t samples_32;
	uint32_t samples_other;
	uint32_t frame_length;
	uint32_t unknown_type;
	uint32_t length_mismatch;

	//uint32_t bytes_droped;

	// dma specific data
	uint32_t dma_errors;		// counts how often a dma transfer had to be skipped because

	// common data
	uint32_t irq_period;				// time passed between irq in us
	uint32_t irq_duration_copy_start;	// time passed until copy started
	uint32_t irq_duration;				// time passed to finish irq processing
	uint32_t irq_duration_copy;  		// time passed for copy operation
	uint32_t total_irq_count;
	uint32_t max_fifo_count; 	// max fifo word count seen since driver start
	uint32_t fifo_count;		// last fifo word count seen
	uint32_t fifo_empty;		// count how often no fifo words had been when irq was asserted
	uint32_t fifo_count_after_copy;	// how many words were in the fifo when copy operation finished

	struct timespec irq_last_time;
	struct timespec irq_start_time;
	struct timespec copy_start_time;

} daqdrv_statistic_t;

typedef struct {
	volatile size_t	 		wrOffs;			 // current write position in the ring buffer after latest irq (DO NOT ACCESS THIS PLS!)
	size_t	 				bufferSize;		 // total size of the ring buffer (= chunkSize * chunkCount)
	size_t 	 				magic; // constant value 0xcafeaffe
	// chunk based data transfer

	volatile size_t 		chunkReadyIndex; // index of the chunk that just became ready
	size_t 					chunkSize;
	size_t 					mmap_chunk_span; // a multitude of HESS_SAMPLE_DATA_SIZE aligned to PAGE_SIZE (because of mmap)
	size_t 					chunkCount;		 // number of available chunks (can change from driver load to unload)


} daqdrv_shared_data_t;

#endif /* DAQDRV_DEFINES_H_ */
