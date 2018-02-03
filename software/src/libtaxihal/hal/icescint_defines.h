/*
 * powerDistributionBox.h
 *
 *  Created on: Jan 20, 2015
 *      Author: marekp
 */

#ifndef ICESCINT_HAL_ICESCINT_DEFINES_H_
#define ICESCINT_HAL_ICESCINT_DEFINES_H_

// 8 bit rw register:
//   bit 0 - channel 0
//   bit 1 - channel 1
//   ...
//   bit 7 - channel 7

#define ICESCINT_FIFO_WIDTH_WORDS 			9
#define ICESCINT_NUMBEROFCHANNELS			8

#define BASE_ICESCINT_READOUT										0x0000 // ## rename to BASE_ICESCINT

#define OFFS_ICESCINT_TRIGGER_DELAY_RISINGEDGE						0x0c // small delay for trigger edge timing to work
#define OFFS_ICESCINT_TRIGGER_DELAY_DATA							0x0e // will get the same value as the serdesDelay

#define OFFS_ICESCINT_READOUT_EVENTFIFO								0x20
#define OFFS_ICESCINT_READOUT_EVENTFIFOWORDCOUNT					0x2a
#define OFFS_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG					0x100
#define MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4SAMPLING	(1<<0)
#define MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4BASELINE	(1<<1)
#define MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4CHARGE		(1<<2)
#define MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4TIMING		(1<<3)
#define MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TRIGGERTIMING	(1<<5)
#define MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TEST_DATA1		(1<<8)
#define MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TEST_DATA2		(1<<9)
#define MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_WHITERABBIT		(1<<12)
#define MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_GPS				(1<<13)
#define MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_PIXELRATES		(1<<14)
#define MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DEBUG			(1<<15)

#define OFFS_ICESCINT_TRIGGER_THRESHOLD								0x50
#define SPAN_ICESCINT_TRIGGER_THRESHOLD								2
#define COUNT_ICESCINT_TRIGGER_THRESHOLD							8

#define OFFS_ICESCINT_PIXELTRIGGERCOUNTER_RESET						0x40
#define OFFS_ICESCINT_PIXELTRIGGERCOUNTER_PERIOD					0x42
#define OFFS_ICESCINT_PIXELTRIGGERCOUNTER_RATE						0x30
#define SPAN_ICESCINT_PIXELTRIGGERCOUNTER_RATE						2
#define COUNT_ICESCINT_PIXELTRIGGERCOUNTER_RATE						8
#define OFFS_ICESCINT_PIXELDEADTIMETRIGGERCOUNTER_RATE				0x130
#define SPAN_ICESCINT_PIXELDEADTIMETRIGGERCOUNTER_RATE				2
#define COUNT_ICESCINT_PIXELDEADTIMETRIGGERCOUNTER_RATE				8

#define OFFS_ICESCINT_READOUT_NUMBEROFSAMPLESTOREAD					0xa6
#define OFFS_ICESCINT_READOUT_READOUTMODE							0xaa

#define OFFS_ICESCINT_TRIGGERLOGIC_SERDESDELAY							0x1d0
#define OFFS_ICESCINT_TRIGGERLOGIC_SINGLESOFTTRIGGER					0x1d2
#define OFFS_ICESCINT_TRIGGERLOGIC_TRIGGERMASK							0x1d4
#define OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORENABLE			0x1d8
#define OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORPERIOD_LOW		0x1da
#define OFFS_ICESCINT_TRIGGERLOGIC_SOFTTRIGGERGENERATORPERIOD_HIGH		0x1dc
#define OFFS_ICESCINT_TRIGGERLOGIC_RATECOUNTER_RESET					0x1de
#define OFFS_ICESCINT_TRIGGERLOGIC_RATECOUNTER_PERIOD					0x1e0

#define OFFS_ICESCINT_READOUT_CORRECTIONRAMCHANNELMASK				0xe0
#define OFFS_ICESCINT_READOUT_CORRECTIONRAMADDRESS					0xe2
#define OFFS_ICESCINT_READOUT_CORRECTIONRAMWRITEVALUE				0xe4

#define OFFS_ICESCINT_READOUT_BASELINESTART							0xe6
#define OFFS_ICESCINT_READOUT_BASELINESTOP							0xe8

#define OFFS_ICESCINT_ICETAD_PANELPOWER								0xf0

#define OFFS_ICESCINT_IRQ_FIFO_EVENTCOUNT_THRESH	0x104	// threshold of event words in fifo, at which an IRQ is asserted
#define OFFS_ICESCINT_IRQ_CTRL						0x106	//
#define BIT_ICESCINT_IRQ_CTRL_IRQ_EN				0
#define OFFS_ICESCINT_IRQ_FORCE						0x108	// writing to this address generates a single IRQ, no matter if irq are enabled or not

#define OFFS_ICESCINT_READOUT_RS485DATA					0x300
#define OFFS_ICESCINT_READOUT_RS485DATASEND				0x310	// write 1 to start tx, read to get tx busy
#define OFFS_ICESCINT_READOUT_RS485RXBUSY				0x312	// ro
#define OFFS_ICESCINT_READOUT_RS485FIFOFULL				0x314	// ro
#define OFFS_ICESCINT_READOUT_RS485FIFOEMPTY			0x316 	// ro
#define OFFS_ICESCINT_READOUT_RS485FIFORESET			0x318
#define OFFS_ICESCINT_READOUT_RS485FIFOREAD				0x31a
#define OFFS_ICESCINT_READOUT_RS485SOFTTXENABLE			0x31c
#define OFFS_ICESCINT_READOUT_RS485SOFTTXMASK			0x31e
#define OFFS_ICESCINT_READOUT_RS485DATAWORDS			0x320	// ## span 8?!

#define OFFS_ICESCINT_WHITERABBIT_NEWDATALATCHED						0x0400	// rw, 1bit, any write will reset this register, read will show if new data is there and will also latch all "*IRIGDATA_*" values
#define OFFS_ICESCINT_WHITERABBIT_IRIGDATA_BCD_0						0x0402	// ro, 16bit, min, sec
#define OFFS_ICESCINT_WHITERABBIT_IRIGDATA_BCD_1						0x0404	// ro, 8bit, hour
#define OFFS_ICESCINT_WHITERABBIT_IRIGDATA_BCD_2						0x0406	// ro, 12bit, day
#define OFFS_ICESCINT_WHITERABBIT_IRIGDATA_BCD_3						0x0408	// ro, 8bit, year (from 1970!?)
#define OFFS_ICESCINT_WHITERABBIT_IRIGDATA_BINARY_SECONDS				0x040a	// ro, 16bit, counter
#define OFFS_ICESCINT_WHITERABBIT_IRIGDATA_BINARY_DAYS					0x040c	// ro, 9bit, binary days
#define OFFS_ICESCINT_WHITERABBIT_IRIGDATA_BINARY_YEARS					0x040e	// ro, 7bit, 7bit binary year

#define OFFS_ICESCINT_WHITERABBIT_IRIGDATA_LSB0							0x0410	// ro, 16bit
#define OFFS_ICESCINT_WHITERABBIT_IRIGDATA_LSB1							0x0412	// ro, 16bit
#define OFFS_ICESCINT_WHITERABBIT_IRIGDATA_LSB2							0x0414	// ro, 16bit
#define OFFS_ICESCINT_WHITERABBIT_IRIGDATA_LSB3							0x0416	// ro, 16bit
#define OFFS_ICESCINT_WHITERABBIT_IRIGDATA_LSB4							0x0418	// ro, 16bit
#define OFFS_ICESCINT_WHITERABBIT_IRIGDATA_MSB							0x041a	// ro, 9bit
#define OFFS_ICESCINT_WHITERABBIT_BITCOUNTER							0x041c	// ro, 8bit
#define OFFS_ICESCINT_WHITERABBIT_ERRORCOUNTER							0x041e	// ro, 16bit
#define OFFS_ICESCINT_WHITERABBIT_PERIOD								0x0420	// rw, 16bit

#define OFFS_ICESCINT_TMP05_STARTCONVERSION								0x0440	// wo, 1bit
#define OFFS_ICESCINT_TMP05_BUSY										0x0440	// ro, 1bit
#define OFFS_ICESCINT_TMP05_TL											0x0442	// ro, 16bit
#define OFFS_ICESCINT_TMP05_TH											0x0444	// ro, 16bit

// GPS registers are not latched during readout
#define OFFS_ICESCINT_GPS_WEEK										0x0480	// ro, 16bit
#define OFFS_ICESCINT_GPS_QUANTIZATIONERROR_H						0x0482	// ro, 16bit
#define OFFS_ICESCINT_GPS_QUANTIZATIONERROR_L						0x0484	// ro, 16bit
#define OFFS_ICESCINT_GPS_TIMEOFWEEKMS_H							0x0486	// ro, 16bit
#define OFFS_ICESCINT_GPS_TIMEOFWEEKMS_L							0x0488	// ro, 16bit
#define OFFS_ICESCINT_GPS_TIMEOFWEEKSUBMS_H							0x048a	// ro, 16bit
#define OFFS_ICESCINT_GPS_TIMEOFWEEKSUBMS_L							0x048c	// ro, 16bit
#define OFFS_ICESCINT_GPS_DIFFERENCEGPSTOLOCALCLOCK					0x048e	// ro, 16bit
#define OFFS_ICESCINT_GPS_PERIOD									0x0490	// rw, 16bit
#define OFFS_ICESCINT_GPS_NEWDATALATCHED							0x0492	// rw, 1bit

#define MASK_ICESCINT_DATATYPE										0xf000
#define VALUE_ICESCINT_DATATYPE_HEADER								0x1000
#define VALUE_ICESCINT_DATATYPE_TRIGGERTIMING						0x3000
#define VALUE_ICESCINT_DATATYPE_DSR4SAMPLING						0x4000
#define VALUE_ICESCINT_DATATYPE_DSR4BASELINE						0x5000
#define VALUE_ICESCINT_DATATYPE_DSR4CHARGE							0x6000
#define VALUE_ICESCINT_DATATYPE_DSR4TIMING							0x7000
#define VALUE_ICESCINT_DATATYPE_DATAPERSECOND						0x8000
#define VALUE_ICESCINT_DATATYPE_TESTDATA_STATICEVENTFIFOHEADER		0xa000
#define VALUE_ICESCINT_DATATYPE_TESTDATA_COUNTEREVENTFIFOHEADER		0xb000
#define VALUE_ICESCINT_DATATYPE_TESTDATA_COUNTER					0xc000
#define VALUE_ICESCINT_DATATYPE_DEBUG								0xf000

// helper function to determine if a icescint header is valid
// returns 1 if header is a valid icescint header
// returns 0 otherwise
inline static int icescint_isValidHeader(unsigned short  _header)
{
	switch (_header & MASK_ICESCINT_DATATYPE) {
	case VALUE_ICESCINT_DATATYPE_HEADER:
	case VALUE_ICESCINT_DATATYPE_DEBUG:
	case VALUE_ICESCINT_DATATYPE_TRIGGERTIMING:
	case VALUE_ICESCINT_DATATYPE_DSR4SAMPLING:
	case VALUE_ICESCINT_DATATYPE_DSR4CHARGE:
	case VALUE_ICESCINT_DATATYPE_DSR4TIMING:
	case VALUE_ICESCINT_DATATYPE_DATAPERSECOND:
	case VALUE_ICESCINT_DATATYPE_TESTDATA_STATICEVENTFIFOHEADER:
	case VALUE_ICESCINT_DATATYPE_TESTDATA_COUNTEREVENTFIFOHEADER:
	case VALUE_ICESCINT_DATATYPE_TESTDATA_COUNTER:
		return 1;
	default:
		return 0;
	}
}


#endif // ICESCINT_HAL_ICESCINT_DEFINES_H_
