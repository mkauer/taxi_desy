#ifndef HAL_BITS_H__
#define HAL_BITS_H__

#if IS_KERNEL_SOURCE == 0
	#include <stdint.h>
#endif

#define __MAKE_BOOL(VAL) ((VAL)?1:0)
#define numberOfElemts(a) (sizeof(a)/sizeof((a)[0]))

// 8 bit manipulation routines
static inline uint8_t bitValue8(uint8_t index)
{
	return (1<<index);
}
static inline uint8_t setBit8(uint8_t value, uint8_t index)
{
	return (value | bitValue8(index));
}
static inline uint8_t setMask8(uint8_t value, uint8_t mask)
{
	return (value | mask);
}
static inline uint8_t clrBit8(uint8_t value, uint8_t index)
{
	return (value & ~bitValue8(index));
}
static inline uint8_t clrMask8(uint8_t value, uint8_t mask)
{
	return (value & ~(mask));
}
static inline uint8_t changeBitVal8(uint8_t value, uint8_t index_, int true_means_set__false_means_clear)
{
	if (true_means_set__false_means_clear) {return setBit8(value, index_);}
	else {return clrBit8(value, index_);}
}
static inline int testBitVal8(uint8_t value, uint8_t index)
{
	return (value & (1<<index))?1:0;
}

// 16 bit manipulation routines
static inline uint16_t bitValue16(uint16_t index)
{
	return ((uint16_t)(1)<<index);
}
static inline uint16_t setBit16(uint16_t value, uint16_t index)
{
	return (value | bitValue16(index));
}
static inline uint16_t setMask16(uint16_t value, uint16_t mask)
{
	return (value | mask);
}
static inline uint16_t clrBit16(uint16_t value, uint16_t index)
{
	return (value & ~bitValue16(index));
}
static inline uint16_t clrMask16(uint16_t value, uint16_t mask)
{
	return (value & ~(mask));
}
static inline uint16_t changeBitVal16(uint16_t value, uint16_t index, int true_means_set__false_means_clear)
{
	if (true_means_set__false_means_clear) {return setBit16(value, index);}
	else {return clrBit16(value, index);}
}
static inline uint16_t changeMask16(uint16_t value, uint16_t mask, int true_means_set__false_means_clear)
{
	if (true_means_set__false_means_clear) {return setMask16(value, mask);}
	else {return clrMask16(value, mask);}
}
static inline int testBitVal16(uint16_t value, uint16_t index) // ## return bool_t...
{
	return (value & ((uint16_t)(1)<<index))?1:0;
}
//static inline int testBitMask16(uint16_t value, uint16_t index) // problematic behavior: it is not clear what should be done if the mask has more than 1 used bit and only some of them are inside the value
//{
//	return (value & index)?1:0;
//}

// 32 bit manipulation routines
static inline uint32_t bitValue32(uint16_t index)
{
	return ((uint32_t)(1)<<index);
}
static inline uint32_t setBit32(uint32_t value, uint16_t index)
{
	return (value | bitValue32(index));
}
static inline uint32_t setMask32(uint32_t value, uint16_t mask)
{
	return (value | mask);
}
static inline uint32_t clrBit32(uint32_t value, uint16_t index)
{
	return (value & ~bitValue32(index));
}
static inline uint32_t clrMask32(uint32_t value, uint16_t mask)
{
	return (value & ~(mask));
}
static inline uint32_t changeBitVal32(uint32_t value, uint16_t index, int true_means_set__false_means_clear)
{
	if (true_means_set__false_means_clear) {return setBit32(value, index);}
	else {return clrBit32(value, index);}
}
static inline int testBitVal32(uint32_t value, uint16_t index)
{
	return ((value & ((uint32_t)(1)<<index))?1:0);
}

static inline uint16_t clipValueMax(uint16_t _value, uint16_t _maxValue)
{
	uint16_t ret = 0;
	if(_value >= _maxValue) {ret = _maxValue;} // assert here....
	else {ret = _value;}
	return ret;
}

static inline uint16_t clipValueMin(uint16_t _value, uint16_t _minValue)
{
	uint16_t ret = 0;
	if(_value <= _minValue) {ret = _minValue;} // assert here....
	else {ret = _value;}
	return ret;
}

static inline uint16_t clipValueMinMax(uint16_t _value, uint16_t _minValue, uint16_t _maxValue)
{
	uint16_t ret = 0;
	ret = clipValueMin(_value, _minValue);
	ret = clipValueMax(ret, _maxValue);
	return ret;
}

static inline uint32_t convert_2x_uint16_to_uint32(uint16_t _valueH, uint16_t _valueL)
{
	uint32_t ret = _valueH;
	ret = ret << 16;
	ret = ret + _valueL;
	return ret;
}

#endif
