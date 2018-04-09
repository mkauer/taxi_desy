/*
 * powerDistributionBox.h
 *
 *  Created on: Jan 20, 2015
 *      Author: marekp
 */

#ifndef ICESCINT_HAL_ICESCINT_H_
#define ICESCINT_HAL_ICESCINT_H_

#include <hal/polarstern_defines.h>
#include "bits.h"
#include "hal/smc.h"
#include <stdexcept>

#include "common.h"

//#undef BASE_COMMON

typedef int bool_t; // ## types.h !?!

static inline bool_t polarstern_isRatesNewData(void)
{
	uint16_t ret = IORD_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_PIXELTRIGGERRATECOUNTER_NEWDATALATCHED);
	return ret;
}
static inline void polarstern_doResetRatesNewData(void)
{
	IOWR_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_PIXELTRIGGERRATECOUNTER_NEWDATALATCHED, 0);
}

static inline void polarstern_setTriggerThreshold(int _channel, uint16_t _threshold)
{
	// polarstern trigger threshold will be the first 8 channels of group A and B
	uint16_t offset = 0;
	_channel = clipValueMinMax(_channel, 0, POLARSTERN_NUMBEROFCHANNELS-1);

	if((_channel >= 0) && (_channel <= 7))
	{
		offset = _channel * SPAN_COMMON_ANALOGFRONTENDDAC;
		IOWR_16DIRECT(BASE_COMMON_ANALOGFRONTENDDAC_GROUPA, OFFS_COMMON_ANALOGFRONTENDDAC_VALUE + offset, _threshold);
	}
	if((_channel >= 8) && (_channel <= 15))
	{
		offset = (_channel-8) * SPAN_COMMON_ANALOGFRONTENDDAC;
		IOWR_16DIRECT(BASE_COMMON_ANALOGFRONTENDDAC_GROUPB, OFFS_COMMON_ANALOGFRONTENDDAC_VALUE + offset, _threshold);
	}
}
static inline uint16_t polarstern_getTriggerThreshold(int _channel)
{
	uint16_t offset = 0;
	uint16_t ret = 0;
	_channel = clipValueMinMax(_channel, 0, POLARSTERN_NUMBEROFCHANNELS-1);

	if((_channel >= 0) && (_channel <= 7))
	{
		offset = _channel * SPAN_COMMON_ANALOGFRONTENDDAC;
		ret = IORD_16DIRECT(BASE_COMMON_ANALOGFRONTENDDAC_GROUPA, OFFS_COMMON_ANALOGFRONTENDDAC_VALUE + offset);
	}
	if((_channel >= 8) && (_channel <= 15))
	{
		offset = (_channel-8) * SPAN_COMMON_ANALOGFRONTENDDAC;
		ret = IORD_16DIRECT(BASE_COMMON_ANALOGFRONTENDDAC_GROUPB, OFFS_COMMON_ANALOGFRONTENDDAC_VALUE + offset);
	}

	return ret;
}
static inline void polarstern_setAllTriggerThreshold(uint16_t _threshold)
{
	for(int i=0;i<POLARSTERN_NUMBEROFCHANNELS;i++) {polarstern_setTriggerThreshold(i, _threshold);}
}

static inline uint16_t polarstern_getPixelTriggerRates(int _channel)
{
	uint16_t offset = 0;
	uint16_t ret = 0;

	offset = clipValueMinMax(_channel, 0, POLARSTERN_NUMBEROFCHANNELS-1) * SPAN_POLARSTERN_PIXELTRIGGERRATECOUNTER_VALUE;
	ret = IORD_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_PIXELTRIGGERRATECOUNTER_VALUE + offset);

	return ret;
}

void polarstern_doIrq(void) // force single irq
{
	IOWR_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_IRQ_FORCE, 1);
}
static inline void polarstern_setIrqEnable(uint16_t _enable)
{
	IOWR_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_IRQ_CONTROL, changeBitVal16(0, BIT_POLARSTERN_IRQ_CONTROL_IRQ_EN, _enable)); // interrupt disable
}
static inline int polarstern_isIrqEnable(void)
{
	return testBitVal16(IORD_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_IRQ_CONTROL), BIT_POLARSTERN_IRQ_CONTROL_IRQ_EN);
}

static inline void polarstern_setPanelHv(int _panel, uint16_t _value)
{
	// polarstern trigger threshold will be the first 8 channels of group A and B
	uint16_t offset;
	offset = clipValueMinMax(_panel, 0, 1) * SPAN_COMMON_ANALOGFRONTENDDAC_CHIP * 2; // hv is on dac b ch.0 and ch.2

	IOWR_16DIRECT(BASE_COMMON_ANALOGFRONTENDDAC_GROUPA, OFFS_COMMON_ANALOGFRONTENDDAC_VALUECHIPB + offset, _value);

}
static inline uint16_t polarstern_getPanelHv(int _panel)
{
	uint16_t offset;
	offset = clipValueMinMax(_panel, 0, 1) * SPAN_COMMON_ANALOGFRONTENDDAC_CHIP * 2; // hv is on dac b ch.0 and ch.2;

	return IORD_16DIRECT(BASE_COMMON_ANALOGFRONTENDDAC_GROUPA, OFFS_COMMON_ANALOGFRONTENDDAC_VALUECHIPB + offset);
}

//static inline void icescint_doSingleSoftTrigger(void)
//{
//	IOWR_16DIRECT(BASE_POLARSTERN, OFFS_ICESCINT_TRIGGERLOGIC_SINGLESOFTTRIGGER, 1);
//}

static inline void polarstern_setIrqAtFifoWords(uint16_t _value)
{
	IOWR_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_IRQ_ATFIFOWORDS, _value);
}
static inline uint16_t polarstern_getIrqAtFifoWords(void)
{
	return IORD_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_IRQ_ATFIFOWORDS);
}

static inline void polarstern_setIrqAtEventCount(uint16_t _value)
{
	IOWR_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_IRQ_ATEVENTCOUNT, _value);
}
static inline uint16_t polarstern_getIrqAtEventCount(void)
{
	return IORD_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_IRQ_ATEVENTCOUNT);
}

static inline void polarstern_setPixelTriggerCounterPeriod(uint16_t _value)
{
	IOWR_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_PIXELTRIGGERRATECOUNTER_PERIOD, _value);
}
static inline uint16_t polarstern_getPixelTriggerCounterPeriod(void)
{
	return IORD_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_PIXELTRIGGERRATECOUNTER_PERIOD);
}

static inline void polarstern_doResetPixelTriggerCounter(void)
{
	IOWR_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_PIXELTRIGGERRATECOUNTER_RESET, 0xffff);
	IOWR_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_PIXELTRIGGERRATECOUNTER_RESET2, 0xffff);
}

static inline void polarstern_doResetPixelTriggerCounterAndTime(void)
{
	IOWR_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_PIXELTRIGGERRATECOUNTER_RESET3, 0x3);
}



static inline void polarstern_setEventFifoPacketConfig(uint16_t _value)
{
	IOWR_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_READOUT_EVENTFIFOPACKETCONFIG, _value);
}
static inline uint16_t polarstern_getEventFifoPacketConfig(void)
{
	return IORD_16DIRECT(BASE_POLARSTERN, OFFS_POLARSTERN_READOUT_EVENTFIFOPACKETCONFIG);
}


#endif
