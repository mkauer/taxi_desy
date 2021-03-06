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
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_TRIGGERMASK, _mask);
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
void icescint_setIrqEnable(int _enable)
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
	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_TRIGGERMASK);
}

static inline void icescint_doSingleSoftTrigger(void)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_SINGLESOFTTRIGGER, 1);
}

static inline void icescint_setSoftTriggerGeneratorEnable(bool_t _enable)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_SOFTTRIGGERGENERATORENABLE, __MAKE_BOOL(_enable));
}
static inline bool_t iceSint_getSoftTriggerGeneratorEnable(void)
{
	return __MAKE_BOOL(IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_SOFTTRIGGERGENERATORENABLE));
}

static inline void icescint_setSoftTriggerGeneratorPeriod(uint32_t _value)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_SOFTTRIGGERGENERATORPERIOD_LOW, _value&0xffff);
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_SOFTTRIGGERGENERATORPERIOD_HIGH, _value>>16);
}

static inline uint32_t icescint_getSoftTriggerGeneratorPeriod(void)
{
	uint32_t temp;
	temp = IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_SOFTTRIGGERGENERATORPERIOD_HIGH) << 16 +
		   IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_SOFTTRIGGERGENERATORPERIOD_LOW);
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
void icescint_doRs485Send(uint8_t _panelMask)
{
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_RS485DATASEND, _panelMask);
}
void icescint_setRs485Data(uint8_t _data, uint8_t _panel)
{
	_panel = _panel & 0x7;
	IOWR_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_RS485DATA+(2*_panel), _data);
}
uint8_t icescint_getRs485Data(uint8_t _panel)
{
	_panel = _panel & 0x7;
	return IORD_16DIRECT(BASE_ICESCINT_READOUT, OFFS_ICESCINT_READOUT_RS485DATA+(2*_panel));
}
void icescint_doRs485SendData(uint8_t _data, uint8_t _panel)
{
	_panel = _panel & 0x7;
	icescint_setRs485Data(_data, _panel);
	icescint_doRs485Send(1<<_panel);
}

#endif
