/*
 * common_defines.h
 *
 *  Created on: Apr 6, 2018
 *      Author: taxidev
 */

#ifndef SOURCE_DIRECTORY__SRC_LIBTAXIHAL_HAL_COMMON_DEFINES_H_
#define SOURCE_DIRECTORY__SRC_LIBTAXIHAL_HAL_COMMON_DEFINES_H_

#define BASE_COMMON													0x0000

//--- a copy of this block is also in the daqdriver :( ------------------------
#define BASE_COMMON_READOUT											(0x100 + BASE_COMMON)
#define OFFS_COMMON_READOUT_EVENTFIFODATA							0x0
#define OFFS_COMMON_READOUT_EVENTFIFOCLEAR							0x2	// wo, 1bit any write will clear the fifo
#define OFFS_COMMON_READOUT_EVENTFIFOWORDCOUNT						0x4
#define OFFS_COMMON_READOUT_EVENTFIFOWORDSPERSLICE					0x6
//-----------------------------------------------------------------------------

#define BASE_COMMON_GPS												(0x200 + BASE_COMMON)
#define OFFS_COMMON_GPS_PERIOD										0x00	// rw, 16bit
#define OFFS_COMMON_GPS_NEWDATALATCHED								0x02	// rw, 1bit any write will reset the latch
#define OFFS_COMMON_GPS_DIFFERENCEGPSTOLOCALCLOCK					0x04	// ro, 16bit
#define OFFS_COMMON_GPS_WEEK										0x06	// ro, 16bit
#define OFFS_COMMON_GPS_QUANTIZATIONERROR_H							0x08	// ro, 16bit
#define OFFS_COMMON_GPS_QUANTIZATIONERROR_L							0x0a	// ro, 16bit
#define OFFS_COMMON_GPS_TIMEOFWEEKMS_H								0x0c	// ro, 16bit
#define OFFS_COMMON_GPS_TIMEOFWEEKMS_L								0x0e	// ro, 16bit
//#define OFFS_COMMON_GPS_TIMEOFWEEKSUBMS_H							0x0x	// ro, 16bit
//#define OFFS_COMMON_GPS_TIMEOFWEEKSUBMS_L							0x0x	// ro, 16bit

#define BASE_COMMON_TMP05											(0x300 + BASE_COMMON)
#define OFFS_COMMON_TMP05_STARTCONVERSION							0x0	// wo, 1bit
#define OFFS_COMMON_TMP05_BUSY										0x0	// ro, 1bit
#define OFFS_COMMON_TMP05_TL										0x2	// ro, 16bit
#define OFFS_COMMON_TMP05_TH										0x4	// ro, 16bit

#define BASE_COMMON_CLOCKDAC									(0x310 + BASE_COMMON)
#define OFFS_COMMON_CLOCKDAC_A									0x0
#define OFFS_COMMON_CLOCKDAC_B									0x2
#define OFFS_COMMON_CLOCKDAC_BUSY								0x4

// 3 DACs (8 dac channels each) look like one DAC with 24 channels
// there are up to 3 groups of '24 channel' DACs per taxi board
#define BASE_COMMON_ANALOGFRONTENDDAC_GROUPA					(0x400 + BASE_COMMON)
#define BASE_COMMON_ANALOGFRONTENDDAC_GROUPB					(0x440 + BASE_COMMON)
#define BASE_COMMON_ANALOGFRONTENDDAC_GROUPC					(0x480 + BASE_COMMON)
#define OFFS_COMMON_ANALOGFRONTENDDAC_INIT						0x00
#define OFFS_COMMON_ANALOGFRONTENDDAC_FORCECHIPA				0x02
#define OFFS_COMMON_ANALOGFRONTENDDAC_FORCECHIPB				0x04
#define OFFS_COMMON_ANALOGFRONTENDDAC_FORCECHIPC				0x06
#define OFFS_COMMON_ANALOGFRONTENDDAC_BUSY						0x08	// ro, 1bit
#define OFFS_COMMON_ANALOGFRONTENDDAC_VALUECHIPA				0x10	// rw, 8bit
#define OFFS_COMMON_ANALOGFRONTENDDAC_VALUECHIPB				0x20	// rw, 8bit
#define OFFS_COMMON_ANALOGFRONTENDDAC_VALUECHIPC				0x30	// rw, 8bit
#define SPAN_COMMON_ANALOGFRONTENDDAC_CHIP						2
#define COUNT_COMMON_ANALOGFRONTENDDAC_CHIP						8
#define OFFS_COMMON_ANALOGFRONTENDDAC_VALUE						0x10	// rw, 8bit
#define SPAN_COMMON_ANALOGFRONTENDDAC							2
#define COUNT_COMMON_ANALOGFRONTENDDAC							24



#endif /* SOURCE_DIRECTORY__SRC_LIBTAXIHAL_HAL_COMMON_DEFINES_H_ */
