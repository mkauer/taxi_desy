/*
 * common.h
 *
 *  Created on: Apr 6, 2018
 *      Author: taxidev
 */

#ifndef SOURCE_DIRECTORY__SRC_LIBTAXIHAL_HAL_COMMON_H_
#define SOURCE_DIRECTORY__SRC_LIBTAXIHAL_HAL_COMMON_H_

#include "common_defines.h"

static inline void common_doFlushEventFifo(void)
{
	IOWR_16DIRECT(BASE_COMMON_READOUT, OFFS_COMMON_READOUT_EVENTFIFOCLEAR, 0x0);
}

static inline uint16_t common_getEventFifoWordsRAW(void)
{
	uint32_t a;
	a=IORD_16DIRECT(BASE_COMMON_READOUT, OFFS_COMMON_READOUT_EVENTFIFOWORDCOUNT);
	return a; // ## * FOO_FIFO_WIDTH_WORDS;
}

// GPS
static inline uint16_t common_isNewGpsData(void)
{
	uint16_t ret = IORD_16DIRECT(BASE_COMMON_GPS, OFFS_COMMON_GPS_NEWDATALATCHED); // will latch the data
	return ret;
}
static inline void common_doResetNewGpsData(void)
{
	IOWR_16DIRECT(BASE_COMMON_GPS, OFFS_COMMON_GPS_NEWDATALATCHED, 0);
}
static inline uint16_t common_getGpsWeek(void)
{
	return IORD_16DIRECT(BASE_COMMON_GPS, OFFS_COMMON_GPS_WEEK);
}
static inline uint32_t common_getGpsQuantizationError(void)
{
	return convert_2x_uint16_to_uint32(IORD_16DIRECT(BASE_COMMON_GPS, OFFS_COMMON_GPS_QUANTIZATIONERROR_H), IORD_16DIRECT(BASE_COMMON_GPS, OFFS_COMMON_GPS_QUANTIZATIONERROR_L));
}
static inline uint32_t common_getGpsTimeOfWeek_ms(void)
{
	return convert_2x_uint16_to_uint32(IORD_16DIRECT(BASE_COMMON_GPS, OFFS_COMMON_GPS_TIMEOFWEEKMS_H), IORD_16DIRECT(BASE_COMMON_GPS, OFFS_COMMON_GPS_TIMEOFWEEKMS_L));
}

// tmp05
static inline void common_doTmp05StartConversion(void)
{
	IOWR_16DIRECT(BASE_COMMON_TMP05, OFFS_COMMON_TMP05_STARTCONVERSION, 1);
}
static inline uint16_t common_isTmp05Busy(void)
{
	return IORD_16DIRECT(BASE_COMMON_TMP05, OFFS_COMMON_TMP05_BUSY);
}
static inline float common_getTmp05Temperature(void)
{
	uint16_t TLcnt= IORD_16DIRECT(BASE_COMMON_TMP05, OFFS_COMMON_TMP05_TL); // first read latched upper 16 bit
	uint16_t THcnt= IORD_16DIRECT(BASE_COMMON_TMP05, OFFS_COMMON_TMP05_TH);
	if (!TLcnt) return 0; // catch devision by zero and return default value
	return 421 - (751 * ((float)THcnt) / TLcnt);
}



#endif /* SOURCE_DIRECTORY__SRC_LIBTAXIHAL_HAL_COMMON_H_ */
