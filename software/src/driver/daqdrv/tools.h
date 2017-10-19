/*
 * tools.h
 *
 *  Created on: Oct 22, 2012
 *      Author: kossatz
 */

#ifndef TOOLS_H_
#define TOOLS_H_

#define COPY_BUF_SIZE   		512 	// Char Device Internal Copy Buffer Size, the larger, the more efficient but

typedef enum
{
	SET, CLR, TGL
} BitModifier;

// align size to 16 bit
inline static size_t alignSize16Bit(size_t value)
{
	return value & (~1);
}

// set the test pins
static inline void setTestPin(unsigned int pin, BitModifier value)
{
	switch (value)
	{
	case SET:
		at91_set_gpio_value(pin, 1);
		break;

	case CLR:
		at91_set_gpio_value(pin, 0);
		break;

	case TGL:
		at91_set_gpio_value(pin, at91_get_gpio_value(pin) ? 0 : 1);
		break;
	}
}


#endif /* TOOLS_H_ */
