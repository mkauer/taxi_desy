/*
 * powerDistributionBox.h
 *
 *  Created on: Jan 20, 2015
 *      Author: marekp
 */

#ifndef ICESCINT_HAL_ICESCINT_H_
#define ICESCINT_HAL_ICESCINT_H_

#include <hal/icescint_defines.h>
#include "bits.h"
#include "hal/smc.h"
#include <stdexcept>

#include "common.h"
#include "drs4.h"

//#undef BASE_COMMON

typedef int bool_t;
#define __MAKE_BOOL(VAL) ((VAL)?1:0)

static inline void icescint_setTriggerMask(uint16_t _mask) //if a bit == 1 channel is deactivated
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_TRIGGERLOGIC_TRIGGERMASK, _mask);
}

//static inline void icesint_doFlushEventFifo(void)
//{
//	common_doFlushEventFifo();
//}

// returns the current event count
// may be locking is not needed here
static inline uint16_t icescint_getEventFifoWords(void)
{
	return common_getEventFifoWordsRAW() * ICESCINT_FIFO_WIDTH_WORDS;
}

// configures the samples typen to be generated (DRS4TIMING, DRS4CHARGE, ... DEBUG)
static inline void icescint_setEventFifoPacketConfig(uint16_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG, _value);
}

static inline uint16_t icescint_getEventFifoPacketConfig(void)
{
	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG);
}

void icescint_doIrq(void)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_IRQ_FORCE, 1);
}

// OBSOLETE CODE, prepare to replace!
//#warning OBSOLETE CODE: iceSint_getEventFifoData will be removed !
//static inline void iceSint_getEventFifoData(uint16_t *_data)
//{
//	for(int i=0;i<ICESCINT_FIFO_WIDTH_WORDS;i++)
//	{
//		*(_data+i) = IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_EVENTFIFO);
//	}
//}

// enable or disable the irq generation
static inline void icescint_setIrqEnable(uint16_t _enable)
{
	IOWR_16DIRECT(BASE_ICESCINT,OFFS_ICESCINT_IRQ_CTRL, changeBitVal16(0, BIT_ICESCINT_IRQ_CTRL_IRQ_EN, _enable)); // interrupt disable
}

// enable or disable the irq generation
static inline int icescint_isIrqEnable(void)
{
	return testBitVal16(IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_IRQ_CTRL), BIT_ICESCINT_IRQ_CTRL_IRQ_EN);
}

static inline void icescint_setIrqAtEventCount(uint16_t _threshold)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_IRQ_ATEVENTCOUNT, _threshold);
}

static inline uint16_t icescint_getIrqAtEventCount(void)
{
	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_IRQ_ATEVENTCOUNT);
}

static inline void icescint_setIrqAtFifoWords(uint16_t _threshold)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_IRQ_ATFIFOWORDS, _threshold);
}

static inline uint16_t icescint_getIrqAtFifoWords(void)
{
	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_IRQ_ATFIFOWORDS);
}

//
// trigger
//
static inline void icescint_setTriggerThreshold(uint16_t _channel, uint16_t _threshold)
{
	uint16_t offset;
	offset = clipValueMinMax(_channel, 0, ICESCINT_NUMBEROFCHANNELS-1) * SPAN_COMMON_ANALOGFRONTENDDAC_CHIP;

	IOWR_16DIRECT(BASE_COMMON_ANALOGFRONTENDDAC_GROUPA, OFFS_COMMON_ANALOGFRONTENDDAC_VALUECHIPA + offset, _threshold);
}
static inline uint16_t icescint_getTriggerThreshold(uint16_t _channel)
{
	uint16_t offset;
	offset = clipValueMinMax(_channel, 0, ICESCINT_NUMBEROFCHANNELS-1) * SPAN_COMMON_ANALOGFRONTENDDAC_CHIP;

	return IORD_16DIRECT(BASE_COMMON_ANALOGFRONTENDDAC_GROUPA, OFFS_COMMON_ANALOGFRONTENDDAC_VALUECHIPA + offset);
}

//
// soft trigger
//
static inline uint16_t icescint_getTriggerMask(void)
{
	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_TRIGGERLOGIC_TRIGGERMASK);
}

static inline void icescint_doSingleSoftTrigger(void)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_TRIGGERLOGIC_SINGLESOFTTRIGGER, 1);
}

static inline void icescint_setSoftTriggerGeneratorEnable(bool_t _enable)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORENABLE, __MAKE_BOOL(_enable));
}
static inline bool_t iceSint_getSoftTriggerGeneratorEnable(void)
{
	return __MAKE_BOOL(IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORENABLE));
}

static inline void icescint_setSoftTriggerGeneratorPeriod(uint32_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORPERIOD_LOW, _value&0xffff);
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORPERIOD_HIGH, _value>>16);
}

static inline uint32_t icescint_getSoftTriggerGeneratorPeriod(void)
{
	uint32_t temp;
	temp = IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORPERIOD_HIGH) << 16 +
		   IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORPERIOD_LOW);
	return temp;
}

//
// pixel trigger counter
//
static inline void icescint_doPixelTriggerCounterReset(void)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_PIXELTRIGGERCOUNTER_RESET, 0);
}
static inline void icescint_setPixelTriggerCounterPeriod(uint32_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_PIXELTRIGGERCOUNTER_PERIOD, _value);
}
static inline uint16_t icescint_getPixelTriggerCounterPeriod(void)
{
	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_PIXELTRIGGERCOUNTER_PERIOD);
}
static inline uint16_t icescint_getPixelTriggerCounterRate(uint16_t _channel)
{
	uint16_t offset;
	offset = clipValueMax(_channel, COUNT_ICESCINT_PIXELTRIGGERCOUNTER_RATE-1)*SPAN_ICESCINT_PIXELTRIGGERCOUNTER_RATE;

	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_PIXELTRIGGERCOUNTER_RATE + offset);
}
static inline int icescint_isTriggerRateNewData(void)
{
	return testBitVal16(IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_PIXELTRIGGERCOUNTER_NEWDATA),0);
}
static inline void icescint_doTriggerRateNewDataReset(bool_t _value)
{
	if(_value){_value = 1;} // ## mask?
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_PIXELTRIGGERCOUNTER_NEWDATA, _value);
}

//
// RS485
//
static inline void icescint_doRs485Send(uint8_t _panelMask)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_RS485DATASEND, _panelMask);
}
static inline void icescint_setRs485Data(uint8_t _data, uint8_t _panel)
{
	_panel = _panel & 0x7;
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_RS485DATA+(2*_panel), _data);
}
static inline uint16_t icescint_getRs485Data(uint8_t _panel)
{
	_panel = _panel & 0x7;
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_RS485FIFOREAD, (1<<_panel));
	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_RS485DATA+(2*_panel));
}
static inline void icescint_doRs485SendData(uint8_t _data, uint8_t _panel)
{
	_panel = _panel & 0x7;
	icescint_setRs485Data(_data, _panel);
	icescint_doRs485Send(1<<_panel);
}
static inline uint16_t icescint_getRs485SoftTriggerMask(void)
{
	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_RS485SOFTTXMASK);
}
static inline void icescint_setRs485SoftTxMask(uint16_t _mask)
{
	return IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_RS485SOFTTXMASK, _mask);
}
//uint16_t icescint_getRs485Data(uint8_t _panel)
//{
//	_panel = clipValueMax(_panel, ICESCINT_NUMBEROFCHANNELS-1);
//	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_RS485DATA+(2*_panel));
//}
static inline void icescint_doRs485FlushRxFifo(uint16_t _panel)
{
//	for(int i=0;i<260;i++)
//	{
//		icescint_getRs485Data(_panel);
//	}
	_panel = _panel & 0x7;
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_RS485FIFORESET, (1<<_panel));
}

static inline uint16_t icescint_getRs485RxFifoWords(uint16_t _panel)
{
	_panel = _panel & 0x7;
	IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_RS485DATAWORDS+(2*_panel));
}

//
//
//
static inline void icescint_setSerdesDelay(uint16_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_TRIGGERLOGIC_SERDESDELAY, _value);
}
static inline uint16_t icescint_getSerdesDelay(void)
{
	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_TRIGGERLOGIC_SERDESDELAY);
}

static inline void icescint_setPanelPowerMask(uint16_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_ICETAD_PANELPOWER, _value);
}
static inline uint16_t icescint_getPanelPowerMask(void)
{
	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_ICETAD_PANELPOWER);
}

static inline void icescint_setPanelPower(uint16_t _channel, uint16_t _value)
{
	uint16_t temp = IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_ICETAD_PANELPOWER);
	temp = changeBitVal16(temp, clipValueMax(_channel,ICESCINT_NUMBEROFCHANNELS-1),__MAKE_BOOL(_value));
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_ICETAD_PANELPOWER, temp);
}
static inline uint16_t icescint_getPanelPower(uint16_t _channel)
{
	uint16_t temp = IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_ICETAD_PANELPOWER);
	return testBitVal16(temp, clipValueMax(_channel,ICESCINT_NUMBEROFCHANNELS-1));
}

static inline void icescint_setBaselineStart(uint16_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_BASELINESTART, _value);
}
static inline uint16_t icescint_getBaselineStart(void)
{
	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_BASELINESTART);
}

static inline void icescint_setBaselineStop(uint16_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_BASELINESTOP, _value);
}
static inline uint16_t icescint_getBaselineStop(void)
{
	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_BASELINESTOP);
}

// IRIGB
static inline uint16_t icescint_isNewIrigData(void)
{
	uint16_t ret = IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_WHITERABBIT_NEWDATALATCHED); // will latch the data
	return ret;
}
static inline void icescint_doResetNewIrigData(void)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_WHITERABBIT_NEWDATALATCHED, 0);
}
static inline void icescint_getIrigRawData(uint16_t *_data)
{
	for(int i=0;i<6;i++)
	{
		*(_data+i) = IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_WHITERABBIT_IRIGDATA_LSB0 + 2*i);
	}
}
static inline uint16_t icescint_getIrigBinaryYear(void)
{
	uint16_t ret = IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_WHITERABBIT_IRIGDATA_BINARY_YEARS); // will latch the data
	return ret;
}
static inline uint16_t icescint_getIrigBinaryDay(void)
{
	uint16_t ret = IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_WHITERABBIT_IRIGDATA_BINARY_DAYS); // will latch the data
	return ret;
}
static inline uint16_t icescint_getIrigBinarySecond(void)
{
	uint16_t ret = IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_WHITERABBIT_IRIGDATA_BINARY_SECONDS); // will latch the data
	return ret;
}

static inline void icescint_doForceMiscData(void)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_MISCDATAFORCE, 0x0);
}

////DEBUG
static inline void icescint_setDebugSetDrs4Chip(uint16_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_DRS4CHIPSELECTOR, _value);
}

static inline uint16_t icescint_getDebugSetDrs4Chip(void)
{
	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_READOUT_DRS4CHIPSELECTOR);
}

//// GPS
//static inline uint16_t icescint_isNewGpsData(void)
//{
//	return common_isNewGpsData();
//}
//static inline void icescint_doResetNewGpsData(void)
//{
//	common_doResetNewGpsData();
//}
//static inline uint16_t icescint_getGpsWeek(void)
//{
//	return common_getGpsWeek();
//}
//static inline uint32_t icescint_getGpsQuantizationError(void)
//{
//	return common_getGpsQuantizationError();
//}
//static inline uint32_t icescint_getGpsTimeOfWeek_ms(void)
//{
//	return common_getGpsTimeOfWeek_ms();
//}
//
//
//// tmp05
//static inline void icescint_doTmp05StartConversion(void)
//{
//	common_doTmp05StartConversion();
//}
//static inline uint16_t icescint_isTmp05Busy(void)
//{
//	return common_isTmp05Busy();
//}
//static inline float icescint_getTmp05Temperature(void)
//{
//	return common_getTmp05Temperature();
//}

//static inline void icescint_set(uint16_t _value)
//{
//	IOWR_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_XXX, _value);
//}
//static inline uint16_t icescint_get(void)
//{
//	return IORD_16DIRECT(BASE_ICESCINT, OFFS_ICESCINT_XXX);
//}

#endif
