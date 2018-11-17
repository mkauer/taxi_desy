/*
 * drs4.h
 *
 *  Created on: Sep 17, 2018
 *      Author: taxidev
 */

#ifndef SOURCE_DIRECTORY__SRC_LIBTAXIHAL_HAL_DRS4_H_
#define SOURCE_DIRECTORY__SRC_LIBTAXIHAL_HAL_DRS4_H_

//#include "drs4_defines.h"
#include <hal/drs4_defines.h>
#include "bits.h"
#include "hal/smc.h"

// sets number of analog samples to read from DRS4
static inline void drs4_setNumberOfSamplesToRead(uint16_t _value)
{
	IOWR_16DIRECT(BASE_DRS4, OFFS_DRS4_NUMBEROFSAMPLESTOREAD, _value);
}
// get number of analog samples to read from DRS4
static inline uint16_t drs4_getNumberOfSamplesToRead(void)
{
	return IORD_16DIRECT(BASE_DRS4, OFFS_DRS4_NUMBEROFSAMPLESTOREAD);
}

static inline void drs4_setDrs4ReadoutMode(uint16_t _value)
{
	IOWR_16DIRECT(BASE_DRS4, OFFS_DRS4_READOUTMODE, _value);
}

static inline uint16_t drs4_getDrs4ReadoutMode(void)
{
	return IORD_16DIRECT(BASE_DRS4, OFFS_DRS4_READOUTMODE);
}

// _channel :  0..7
// _address :  0..1023 , address of the capacitor of the channel
// _value   :  offset to add to the ADC value acquired from the cell / address / capacitor
static inline void drs4_setCorrectionRamValue(uint16_t _channelMask, uint16_t _address, uint16_t _value)
{
	IOWR_16DIRECT(BASE_DRS4, OFFS_DRS4_CORRECTIONRAMADDRESS, _address);
	IOWR_16DIRECT(BASE_DRS4, OFFS_DRS4_CORRECTIONRAMWRITEVALUE, _value);
	IOWR_16DIRECT(BASE_DRS4, OFFS_DRS4_CORRECTIONRAMCHANNELMASK, _channelMask);
}

//static inline uint16_t drs4_getCorrectionRamValue(void)
//{
//	return 0; //IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG);
//}


#endif /* SOURCE_DIRECTORY__SRC_LIBTAXIHAL_HAL_DRS4_H_ */
