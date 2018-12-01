#ifndef LIBTAXI_HAL_UVLOGGER_H_
#define LIBTAXI_HAL_UVLOGGER_H_

#include <hal/uvlogger_defines.h>
#include "bits.h"
#include "hal/smc.h"

#include "common.h"

typedef int bool_t;

static inline void uvlogger_setTriggerThreshold(uint16_t _channel, uint16_t _threshold)
{
	uint16_t offset;
	offset = clipValueMinMax(_channel, 0, UVLOGGER_NUMBEROFCHANNELS-1) * SPAN_UVLOGGER_DACBUS1;

	IOWR_16DIRECT(BASE_UVLOGGER_DACBUS1, OFFS_UVLOGGER_DACBUS1_TRIGGERTHRESHOLDS + offset, _threshold);
}
static inline uint16_t uvlogger_getTriggerThreshold(uint16_t _channel)
{
	uint16_t offset;
	offset = clipValueMinMax(_channel, 0, UVLOGGER_NUMBEROFCHANNELS-1) * SPAN_UVLOGGER_DACBUS1;

	return IORD_16DIRECT(BASE_UVLOGGER_DACBUS1, OFFS_UVLOGGER_DACBUS1_TRIGGERTHRESHOLDS + offset);
}

static inline void uvlogger_setOffsetVoltage(uint16_t _channel, uint16_t _threshold)
{
	uint16_t offset;
	offset = clipValueMinMax(_channel, 0, UVLOGGER_NUMBEROFCHANNELS-1) * SPAN_UVLOGGER_DACBUS1;

	IOWR_16DIRECT(BASE_UVLOGGER_DACBUS1, OFFS_UVLOGGER_DACBUS1_OFFSETVOLTAGES + offset, _threshold);
}
static inline uint16_t uvlogger_getOffsetVoltage(uint16_t _channel)
{
	uint16_t offset;
	offset = clipValueMinMax(_channel, 0, UVLOGGER_NUMBEROFCHANNELS-1) * SPAN_UVLOGGER_DACBUS1;

	return IORD_16DIRECT(BASE_UVLOGGER_DACBUS1, OFFS_UVLOGGER_DACBUS1_OFFSETVOLTAGES + offset);
}

// i2c generic bus interface
static inline void uvlogger_i2c_sendPacket_(uint8_t _value, bool_t _start, bool_t _stop, bool_t _blocking)
{
	size_t offset = OFFS_UVLOGGER_I2C_BASE_A;
	IOWR_16DIRECT(BASE_UVLOGGER + offset, OFFS_UVLOGGER_I2C_DATASEND, _value);

	uint16_t control = 0;
	if(_start) {control |= bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART);}
	if(_stop) {control |= bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP);}
	IOWR_16DIRECT(BASE_UVLOGGER + offset, OFFS_UVLOGGER_I2C_CONTROL, control);

	IOWR_16DIRECT(BASE_UVLOGGER + offset, OFFS_UVLOGGER_I2C_STARTTRANSFER, 0x1);

	if(_blocking)
	{
		while(IORD_16DIRECT(BASE_UVLOGGER + offset, OFFS_UVLOGGER_I2C_BUSY)){}
	}
}

static inline uint16_t uvlogger_i2c_transferPacket(size_t _base_address, uint16_t _value, uint16_t _flags, bool_t _blocking=1)
{
//	size_t offset = OFFS_UVLOGGER_I2C_BASE_A;
	size_t offset = _base_address;

	while(IORD_16DIRECT(BASE_UVLOGGER + offset, OFFS_UVLOGGER_I2C_BUSY))
	{
		usleep(10);
	}

	IOWR_16DIRECT(BASE_UVLOGGER + offset, OFFS_UVLOGGER_I2C_DATASEND, _value);
	IOWR_16DIRECT(BASE_UVLOGGER + offset, OFFS_UVLOGGER_I2C_CONTROL, _flags);
	IOWR_16DIRECT(BASE_UVLOGGER + offset, OFFS_UVLOGGER_I2C_STARTTRANSFER, 0x1);

	if(_blocking)
	{
		while(IORD_16DIRECT(BASE_UVLOGGER + offset, OFFS_UVLOGGER_I2C_BUSY))
		{
			usleep(10);
		}
	}
	return IORD_16DIRECT(BASE_UVLOGGER + offset, OFFS_UVLOGGER_I2C_DATARECEIVE);
}

static inline bool_t uvlogger_i2c_IsBusy(void)
{
	size_t offset = OFFS_UVLOGGER_I2C_BASE_A;
	return __MAKE_BOOL(IORD_16DIRECT(BASE_UVLOGGER + offset, OFFS_UVLOGGER_I2C_BUSY));
}

static inline uint16_t uvlogger_i2c_receivePacket(uint16_t _value)
{
	size_t offset = OFFS_UVLOGGER_I2C_BASE_A;
	return IORD_16DIRECT(BASE_UVLOGGER + offset, OFFS_UVLOGGER_I2C_DATARECEIVE);
}

static inline void uvlogger_i2c_sendByte(size_t _base_address, uint16_t _value, uint16_t _flags=0, bool_t _blocking=1)
{
	uvlogger_i2c_transferPacket(_base_address, _value, _flags, _blocking);
}
static inline uint16_t uvlogger_i2c_receiveByte(size_t _base_address, uint16_t _flags, bool_t _blocking=1)
{
	_flags = _flags | bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION);
	return uvlogger_i2c_transferPacket(_base_address, 0x0, _flags, _blocking);
}

// i2c hv pcb dac [type: dac7678] bus "A"
const int uvlogger_highVoltageChannelUntwister[8] = {0,1,2,4,3,5,6,7};
static inline uint16_t uvlogger_getHighVoltage(uint16_t _channel)
{
	uint16_t value = 0;

	_channel = clipValueMinMax(_channel, 0, UVLOGGER_NUMBEROFCHANNELS-1);
	_channel = clipValueMinMax(_channel, 0, numberOfElemts(uvlogger_highVoltageChannelUntwister)-1);

	_channel = uvlogger_highVoltageChannelUntwister[_channel];

	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_A, UVLOGGER_I2C_ADDRESS_HVDAC_WRITE, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_A, 0x10+_channel);
	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_A, UVLOGGER_I2C_ADDRESS_HVDAC_READ, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
	value = uvlogger_i2c_receiveByte(OFFS_UVLOGGER_I2C_BASE_A, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
	value = (value << 8);
	value = value + uvlogger_i2c_receiveByte(OFFS_UVLOGGER_I2C_BASE_A, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));
	value = (value >> 4);
	return value;
}
static inline void uvlogger_setHighVoltage(uint16_t _channel, uint16_t _voltage)
{
	_channel = clipValueMinMax(_channel, 0, UVLOGGER_NUMBEROFCHANNELS-1);
	_channel = clipValueMinMax(_channel, 0, numberOfElemts(uvlogger_highVoltageChannelUntwister)-1);
	_voltage = clipValueMinMax(_voltage, 0, bitValue16(12)-1);

	_channel = uvlogger_highVoltageChannelUntwister[_channel];

	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_A, UVLOGGER_I2C_ADDRESS_HVDAC_WRITE, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_A, 0x30+_channel);
	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_A, _voltage>>4);
	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_A, (_voltage<<4)&0xff, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));
}
// use the ramping or the current consumption may exceed the power supply limit
static inline void uvlogger_setHighVoltageRamp(uint16_t _channel, uint16_t _voltage, int _stepSize = 100, int _stepSleep = 10000)
{
	uint16_t oldVoltage = uvlogger_getHighVoltage(_channel);
	int diff = _voltage - oldVoltage;

	if(diff > 0) // ramping on increasing HV only
	{
		for(int i=0;i<diff/_stepSize;i++)
		{
			uvlogger_setHighVoltage(_channel, oldVoltage + i*_stepSize);
			usleep(_stepSleep);
		}
	}
	uvlogger_setHighVoltage(_channel, _voltage);
}

static inline uint16_t uvlogger_getTmp10x(size_t _base_address, int _i2cAddress)
{
	uint16_t temp = 0;

	uvlogger_i2c_sendByte(_base_address, I2C_ADDRESS_TO_WRITE(_i2cAddress), bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
	uvlogger_i2c_sendByte(_base_address, 1);
	uvlogger_i2c_sendByte(_base_address, 0xe0, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));

	usleep(350*1000);

	uvlogger_i2c_sendByte(_base_address, I2C_ADDRESS_TO_WRITE(_i2cAddress), bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
	uvlogger_i2c_sendByte(_base_address, 0);
	uvlogger_i2c_sendByte(_base_address, I2C_ADDRESS_TO_READ(_i2cAddress), bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
	temp = uvlogger_i2c_receiveByte(_base_address, 0, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
	temp = temp << 8;
	temp = temp + uvlogger_i2c_receiveByte(_base_address, 0, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));
	temp = temp >> 4;

	return temp;
}

static inline uint16_t uvlogger_getTemperatureMainBoardTmp10x(void)
{
	return uvlogger_getTmp10x(OFFS_UVLOGGER_I2C_BASE_A, UVLOGGER_I2C_ADDRESS_MAINBOARDTMP10X);
}
static inline float uvlogger_getTemperatureMainBoardTmp10x_degC(void)
{
	return 1.0/16 * uvlogger_getTmp10x(OFFS_UVLOGGER_I2C_BASE_A, UVLOGGER_I2C_ADDRESS_MAINBOARDTMP10X);
}

static inline uint16_t uvlogger_getTemperatureFlasherBoardTmp10x(void)
{
	return uvlogger_getTmp10x(OFFS_UVLOGGER_I2C_BASE_F, UVLOGGER_I2C_ADDRESS_FLASHERBOARDTMP10X);
}
static inline float uvlogger_getTemperatureFlasherBoardTmp10x_degC(void)
{
	return 1.0/16 * uvlogger_getTmp10x(OFFS_UVLOGGER_I2C_BASE_F, UVLOGGER_I2C_ADDRESS_FLASHERBOARDTMP10X);
}

// i2c flasher pcb dac [type: dac7678] bus "F"
static inline uint16_t uvlogger_getFlasherVoltage(uint16_t _channel)
{
	uint16_t value = 0;

	_channel = clipValueMinMax(_channel, 0, UVLOGGER_NUMBEROFCHANNELS-1);
	_channel = clipValueMinMax(_channel, 0, numberOfElemts(uvlogger_highVoltageChannelUntwister)-1);

	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_F, I2C_ADDRESS_TO_WRITE(UVLOGGER_I2C_ADDRESS_FLASHERDAC), bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_F, 0x10+_channel);
	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_F, I2C_ADDRESS_TO_READ(UVLOGGER_I2C_ADDRESS_FLASHERDAC), bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
	value = uvlogger_i2c_receiveByte(OFFS_UVLOGGER_I2C_BASE_F, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
	value = (value << 8);
	value = value + uvlogger_i2c_receiveByte(OFFS_UVLOGGER_I2C_BASE_F, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));
	value = (value >> 4);
	return value;
}
static inline void uvlogger_setFlasherVoltage(uint16_t _channel, uint16_t _voltage)
{
	_channel = clipValueMinMax(_channel, 0, UVLOGGER_NUMBEROFCHANNELS-1); // ## ch. 0-2 are in use
	_voltage = clipValueMinMax(_voltage, 0, bitValue16(12)-1);

	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_F, I2C_ADDRESS_TO_WRITE(UVLOGGER_I2C_ADDRESS_FLASHERDAC), bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_F, 0x30+_channel);
	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_F, _voltage>>4);
	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_F, (_voltage<<4)&0xff, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));
}

static inline void uvlogger_setFlasherVoltageReferenceToInternal(int _enable)
{
	uint16_t flag = 0x0;
	if(_enable){flag = 0x10;};
	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_F, I2C_ADDRESS_TO_WRITE(UVLOGGER_I2C_ADDRESS_FLASHERDAC), bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_F, 0x80);
	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_F, 0x0);
	uvlogger_i2c_sendByte(OFFS_UVLOGGER_I2C_BASE_F, flag, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));
}

static inline void uvlogger_setFlasherGeneratorEnable12(uint16_t _mask)
{
	IOWR_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_LEDFLASHER_ENABLEGENERATOR, _mask);
}
static inline void uvlogger_setFlasherGeneratorEnable1(bool_t _enable)
{
	uint16_t temp = IORD_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_LEDFLASHER_ENABLEGENERATOR);
	temp = changeBitVal16(temp, 0, _enable);
	IOWR_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_LEDFLASHER_ENABLEGENERATOR, temp);
}
static inline bool_t uvlogger_getFlasherGeneratorEnable1(void)
{
	return testBitVal16(IORD_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_LEDFLASHER_ENABLEGENERATOR), 0);
}

static inline void uvlogger_setFlasherGeneratorEnable2(bool_t _enable)
{
	uint16_t temp = IORD_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_LEDFLASHER_ENABLEGENERATOR);
	temp = changeBitVal16(temp, 1, _enable);
	IOWR_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_LEDFLASHER_ENABLEGENERATOR, temp);
}
static inline bool_t uvlogger_getFlasherGeneratorEnable2(void)
{
	return testBitVal16(IORD_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_LEDFLASHER_ENABLEGENERATOR), 1);
}

static inline void uvlogger_setFlasherGeneratorPeriod(uint16_t _channel, uint32_t _period)
{
	_channel = _channel & 0x1;
	IOWR_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_LEDFLASHER_GENERATORPERIOD0 + 4*_channel, _period>>16);
	IOWR_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_LEDFLASHER_GENERATORPERIOD0 + 4*_channel + 2, _period&0xffff);
}
static inline uint32_t uvlogger_getFlasherGeneratorPeriod(uint16_t _channel)
{
	uint32_t value = 0;
	_channel = _channel & 0x1;

	value = IORD_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_LEDFLASHER_GENERATORPERIOD0 + 2*_channel);
	value = value << 16;
	value = IORD_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_LEDFLASHER_GENERATORPERIOD0 + 2*_channel + 1);

	return value;
}
static inline void uvlogger_setFlasherGeneratorFrequency(uint16_t _channel, float _Hz)
{
	int period = 118750000 / _Hz;
	uvlogger_setFlasherGeneratorPeriod(_channel, period);
}
static inline float uvlogger_getFlasherGeneratorFrequency(uint16_t _channel)
{
	return 118750000 / uvlogger_getFlasherGeneratorPeriod(_channel);
}

static inline void uvlogger_setFlasherPulseWidth(uint16_t _channel, uint16_t _width)
{
	_channel = _channel & 0x1;
	IOWR_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_LEDFLASHER_PULSEWIDTH0 + 2*_channel, _width);
}
static inline uint32_t uvlogger_getFlasherPulseWidth(uint16_t _channel)
{
	_channel = _channel & 0x1;

	return IORD_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_LEDFLASHER_PULSEWIDTH0 + 2*_channel);
}

static inline void uvlogger_doFlasherSingleShot(uint16_t _channel)
{
	_channel = _channel & 0x1;
	IOWR_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_LEDFLASHER_SINGLESHOT, 1<<_channel);
}

static inline void uvlogger_setHouskeepingPcbLedsEnable(uint16_t _enable)
{
	IOWR_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_HOUSEKEEPING_ENABLEPCBLEDS, _enable);
}
static inline uint16_t uvlogger_getHouskeepingPcbLedsEnable(void)
{
	return IORD_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_HOUSEKEEPING_ENABLEPCBLEDS);
}

static inline void uvlogger_setHouskeepingJ24TestPinsEnable(uint16_t _enable)
{
	IOWR_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_HOUSEKEEPING_ENABLEJ24TESTPINS, _enable);
}
static inline uint16_t uvlogger_getHouskeepingJ24TestPinsEnable(void)
{
	return IORD_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_HOUSEKEEPING_ENABLEJ24TESTPINS);
}

static inline uint16_t uvlogger_getPixelTriggerAllRisingEdgesRate(uint16_t _channel)
{
	uint16_t offset;
	offset = clipValueMax(_channel, COUNT_UVLOGGER_PIXELTRIGGERALLRISINGEDGES_RATE-1)*SPAN_UVLOGGER_PIXELTRIGGERALLRISINGEDGES_RATE;

	return IORD_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_PIXELTRIGGERALLRISINGEDGES_RATE + offset);
}
static inline uint16_t uvlogger_getPixelTriggerFirstHitsDuringGateRate(uint16_t _channel)
{
	uint16_t offset;
	offset = clipValueMax(_channel, COUNT_UVLOGGER_PIXELFIRSTHITSDURINGGATE_RATE-1)*SPAN_UVLOGGER_PIXELFIRSTHITSDURINGGATE_RATE;

	return IORD_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_PIXELFIRSTHITSDURINGGATE_RATE + offset);
}
static inline uint16_t uvlogger_getPixelTriggerAdditionalHitsDuringGateRate(uint16_t _channel)
{
	uint16_t offset;
	offset = clipValueMax(_channel, COUNT_UVLOGGER_PIXELADDITIONALHITSDURINGGATE_RATE-1)*SPAN_UVLOGGER_PIXELADDITIONALHITSDURINGGATE_RATE;

	return IORD_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_PIXELADDITIONALHITSDURINGGATE_RATE + offset);
}

static inline void uvlogger_setRateCounterGateTime(uint16_t _ticks)
{
	IOWR_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_RATECOUNTERGATETIME, _ticks);
}
static inline uint16_t uvlogger_getRateCounterGateTime(void)
{
	return IORD_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_RATECOUNTERGATETIME);
}

static inline void uvlogger_setTriggerLogicDrs4Decimation(uint16_t _value)
{
	IOWR_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_TRIGGERLOGIC_DRS4DECIMATOR, _value);
}
static inline uint16_t uvlogger_getTriggerLogicDrs4Decimation(void)
{
	return IORD_16DIRECT(BASE_UVLOGGER, OFFS_UVLOGGER_TRIGGERLOGIC_DRS4DECIMATOR);
}




#endif
