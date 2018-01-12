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


typedef int bool_t;
#define __MAKE_BOOL(VAL) ((VAL)?1:0)

static inline void icescint_setTriggerMask(uint16_t _mask) //if a bit == 1 channel is deactivated
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_TRIGGERLOGIC_TRIGGERMASK, _mask);
}

static inline void iceSint_flushEventFifo(void)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_EVENTFIFOWORDCOUNT, 0x0);
}

// returns the current event count
// may be locking is not needed here
static inline uint16_t icescint_getEventFifoWords(void)
{
	uint32_t a; //,b;
	a=IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_EVENTFIFOWORDCOUNT);
//	b=IORD_16DIRECT(OFFS_ICESCINT_READOUT_SUBWORDCOUNT);
	return a * ICESCINT_FIFO_WIDTH_WORDS;
}

// sets number of analog samples to read from DRS4
static inline void icescint_setNumberOfSamplesToRead(uint16_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_NUMBEROFSAMPLESTOREAD, _value);
}
// get number of analog samples to read from DRS4
static inline uint16_t icescint_getNumberOfSamplesToRead(void)
{
	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_NUMBEROFSAMPLESTOREAD);
}

// configures the samples typen to be generated (DRS4TIMING, DRS4CHARGE, ... DEBUG)
static inline void icescint_setEventFifoPacketConfig(uint16_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG, _value);
}

static inline uint16_t icescint_getEventFifoPacketConfig(void)
{
	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG);
}

static inline void icescint_setDrs4ReadoutMode(uint16_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_READOUTMODE, _value);
}

static inline uint16_t icescint_getDrs4ReadoutMode(void)
{
	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_READOUTMODE);
}

// _channel :  0..7
// _address :  0..1023 , address of the capacitor of the channel
// _value   :  offset to add to the ADC value acquired from the cell / address / capacitor
static inline void icescint_setCorrectionRamValue(uint16_t _channelMask, uint16_t _address, uint16_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_CORRECTIONRAMADDRESS, _address);
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_CORRECTIONRAMWRITEVALUE, _value);
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_CORRECTIONRAMCHANNELMASK, _channelMask);
}

static inline uint16_t icescint_getCorrectionRamValue(void)
{
	return 0; //IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG);
}

void icescint_doIrq(void)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_IRQ_FORCE, 1);
}

// OBSOLETE CODE, prepare to replace!
//#warning OBSOLETE CODE: iceSint_getEventFifoData will be removed !
//static inline void iceSint_getEventFifoData(uint16_t *_data)
//{
//	for(int i=0;i<ICESCINT_FIFO_WIDTH_WORDS;i++)
//	{
//		*(_data+i) = IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_EVENTFIFO);
//	}
//}

// enable or disable the irq generation
void icescint_setIrqEnable(uint16_t _enable)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT,OFFS_ICESCINT_IRQ_CTRL, changeBitVal16(0, BIT_ICESCINT_IRQ_CTRL_IRQ_EN, _enable)); // interrupt disable
}

// enable or disable the irq generation
int icescint_isIrqEnable(void)
{
	return testBitVal16(IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_IRQ_CTRL), BIT_ICESCINT_IRQ_CTRL_IRQ_EN);
}

// sets the eventcount threshold for irq generation
void icescint_setIrqEventcountThreshold(uint16_t _threshold)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_IRQ_FIFO_EVENTCOUNT_THRESH, _threshold);
}

// sets the eventcount threshold for irq generation
uint16_t icescint_getIrqEventcountThreshold()
{
	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_IRQ_FIFO_EVENTCOUNT_THRESH);
}

//
// trigger
//
void icescint_setTriggerThreshold(uint16_t _channel, uint16_t _threshold)
{
	uint16_t offset;
	offset = clipValueMax(_channel, COUNT_ICESCINT_TRIGGER_THRESHOLD-1)*SPAN_ICESCINT_TRIGGER_THRESHOLD;

	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_TRIGGER_THRESHOLD + offset, _threshold);
}
uint16_t icescint_getTriggerThreshold(uint16_t _channel)
{
	uint16_t offset;
	offset = clipValueMax(_channel, COUNT_ICESCINT_TRIGGER_THRESHOLD-1)*SPAN_ICESCINT_TRIGGER_THRESHOLD;

	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_TRIGGER_THRESHOLD + offset);
}

//
// soft trigger
//
static inline uint16_t icescint_getTriggerMask(void)
{
	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_TRIGGERLOGIC_TRIGGERMASK);
}

static inline void icescint_doSingleSoftTrigger(void)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_TRIGGERLOGIC_SINGLESOFTTRIGGER, 1);
}

static inline void icescint_setSoftTriggerGeneratorEnable(bool_t _enable)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORENABLE, __MAKE_BOOL(_enable));
}
static inline bool_t iceSint_getSoftTriggerGeneratorEnable(void)
{
	return __MAKE_BOOL(IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORENABLE));
}

static inline void icescint_setSoftTriggerGeneratorPeriod(uint32_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORPERIOD_LOW, _value&0xffff);
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORPERIOD_HIGH, _value>>16);
}

static inline uint32_t icescint_getSoftTriggerGeneratorPeriod(void)
{
	uint32_t temp;
	temp = IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORPERIOD_HIGH) << 16 +
		   IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORPERIOD_LOW);
	return temp;
}

//
// pixel trigger counter
//
static inline void icescint_doPixelTriggerCounterReset(void)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_PIXELTRIGGERCOUNTER_RESET, 0);
}
static inline void icescint_setPixelTriggerCounterPeriod(uint32_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_PIXELTRIGGERCOUNTER_PERIOD, _value);
}
static inline uint16_t icescint_getPixelTriggerCounterPeriod(void)
{
	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_PIXELTRIGGERCOUNTER_PERIOD);
}
static inline uint16_t icescint_getPixelTriggerCounterRate(uint16_t _channel)
{
	uint16_t offset;
	offset = clipValueMax(_channel, COUNT_ICESCINT_PIXELTRIGGERCOUNTER_RATE-1)*SPAN_ICESCINT_PIXELTRIGGERCOUNTER_RATE;

	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_PIXELTRIGGERCOUNTER_RATE + offset);
}

//
// RS485
//
static inline void icescint_doRs485Send(uint8_t _panelMask)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_RS485DATASEND, _panelMask);
}
static inline void icescint_setRs485Data(uint8_t _data, uint8_t _panel)
{
	_panel = _panel & 0x7;
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_RS485DATA+(2*_panel), _data);
}
static inline uint16_t icescint_getRs485Data(uint8_t _panel)
{
	_panel = _panel & 0x7;
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_RS485FIFOREAD, (1<<_panel));
	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_RS485DATA+(2*_panel));
}
static inline void icescint_doRs485SendData(uint8_t _data, uint8_t _panel)
{
	_panel = _panel & 0x7;
	icescint_setRs485Data(_data, _panel);
	icescint_doRs485Send(1<<_panel);
}
//uint16_t icescint_getRs485Data(uint8_t _panel)
//{
//	_panel = clipValueMax(_panel, ICESCINT_NUMBEROFCHANNELS-1);
//	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_RS485DATA+(2*_panel));
//}
static inline void icescint_doRs485FlushRxFifo(uint16_t _panel)
{
//	for(int i=0;i<260;i++)
//	{
//		icescint_getRs485Data(_panel);
//	}
	_panel = _panel & 0x7;
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_RS485FIFORESET, (1<<_panel));
}

static inline uint16_t icescint_getRs485RxFifoWords(uint16_t _panel)
{
	_panel = _panel & 0x7;
	IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_RS485DATAWORDS+(2*_panel));
}

//
//
//
static inline void icescint_setSerdesDelay(uint16_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_TRIGGERLOGIC_SERDESDELAY, _value);
}
static inline uint16_t icescint_getSerdesDelay(void)
{
	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_TRIGGERLOGIC_SERDESDELAY);
}

static inline void icescint_setPanelPowerMask(uint16_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_ICETAD_PANELPOWER, _value);
}
static inline uint16_t icescint_getPanelPowerMask(void)
{
	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_ICETAD_PANELPOWER);
}

static inline void icescint_setPanelPower(uint16_t _channel, uint16_t _value)
{
	uint16_t temp = IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_ICETAD_PANELPOWER);
	temp = changeBitVal16(temp, clipValueMax(_channel,ICESCINT_NUMBEROFCHANNELS-1),__MAKE_BOOL(_value));
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_ICETAD_PANELPOWER, temp);
}
static inline uint16_t icescint_getPanelPower(uint16_t _channel)
{
	uint16_t temp = IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_ICETAD_PANELPOWER);
	return testBitVal16(temp, clipValueMax(_channel,ICESCINT_NUMBEROFCHANNELS-1));
}

static inline void icescint_setBaselineStart(uint16_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_BASELINESTART, _value);
}
static inline uint16_t icescint_getBaselineStart(void)
{
	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_BASELINESTART);
}

static inline void icescint_setBaselineStop(uint16_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_BASELINESTOP, _value);
}
static inline uint16_t icescint_getBaselineStop(void)
{
	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_BASELINESTOP);
}

// IRIGB
static inline uint16_t icescint_isNewIrigData(void)
{
	uint16_t ret = IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_WHITERABBIT_NEWDATALATCHED); // will latch the data
	return ret;
}
static inline void icescint_doResetNewIrigData(void)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_WHITERABBIT_NEWDATALATCHED, 0);
}
static inline void icescint_getIrigRawData(uint16_t *_data)
{
	for(int i=0;i<6;i++)
	{
		*(_data+i) = IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_WHITERABBIT_IRIGDATA_LSB0 + 2*i);
	}
}
static inline uint16_t icescint_getIrigBinaryYear(void)
{
	uint16_t ret = IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_WHITERABBIT_IRIGDATA_BINARY_YEARS); // will latch the data
	return ret;
}
static inline uint16_t icescint_getIrigBinaryDay(void)
{
	uint16_t ret = IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_WHITERABBIT_IRIGDATA_BINARY_DAYS); // will latch the data
	return ret;
}
static inline uint16_t icescint_getIrigBinarySecond(void)
{
	uint16_t ret = IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_WHITERABBIT_IRIGDATA_BINARY_SECONDS); // will latch the data
	return ret;
}

// GPS
static inline uint16_t icescint_isNewGpsData(void)
{
	uint16_t ret = IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_GPS_NEWDATALATCHED); // will latch the data
	return ret;
}
static inline void icescint_doResetNewGpsData(void)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_GPS_NEWDATALATCHED, 0);
}
static inline uint16_t icescint_getGpsWeek(void)
{
	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_GPS_WEEK);
}
static inline uint32_t icescint_getGpsQuantizationError(void)
{
	return convert_2x_uint16_to_uint32(IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_GPS_QUANTIZATIONERROR_H), IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_GPS_QUANTIZATIONERROR_L));
}
static inline uint32_t icescint_getGpsTimeOfWeek_ms(void)
{
	return convert_2x_uint16_to_uint32(IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_GPS_TIMEOFWEEKMS_H), IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_GPS_TIMEOFWEEKMS_L));
}
static inline uint32_t icescint_getGpsTimeOfWeek_subms(void)
{
	return convert_2x_uint16_to_uint32(IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_GPS_TIMEOFWEEKSUBMS_H), IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_GPS_TIMEOFWEEKSUBMS_L));
}

//static inline void icescint_set(uint16_t _value)
//{
//	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_XXX, _value);
//}
//static inline uint16_t icescint_get(void)
//{
//	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_XXX);
//}

#endif
