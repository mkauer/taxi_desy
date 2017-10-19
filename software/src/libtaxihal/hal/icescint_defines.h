/*
 * powerDistributionBox.h
 *
 *  Created on: Jan 20, 2015
 *      Author: marekp
 */

#ifndef ICESCINT_HAL_ICESCINT_DEFINES_H_
#define ICESCINT_HAL_ICESCINT_DEFINES_H_


#define ICESCINT_FIFO_WIDTH_WORDS 			9
#define ICESCINT_NUMBEROFCHANNELS			8

#define BASE_ICESCINT_READOUT										0x0000
#define OFFS_ICESCINT_READOUT_EVENTFIFO								0x20
#define OFFS_ICESCINT_READOUT_EVENTFIFOWORDCOUNT					0x2a
#define OFFS_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG					0x100
#define VALUE_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4SAMPLING	(1<<0)
#define VALUE_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4BASELINE	(1<<1)
#define VALUE_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4CHARGE		(1<<2)
#define VALUE_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4TIMING		(1<<3)
#define VALUE_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TRIGGERTIMING	(1<<5)
#define VALUE_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TEST_DATA		(1<<9)
#define VALUE_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DEBUG			(1<<12)

#define OFFS_ICESCINT_TRIGGER_THRESHOLD								0x50
#define SPAN_ICESCINT_TRIGGER_THRESHOLD								2
#define COUNT_ICESCINT_TRIGGER_THRESHOLD							8

#define OFFS_ICESCINT_PIXELTRIGGERCOUNTER_RESET						0x40
#define OFFS_ICESCINT_PIXELTRIGGERCOUNTER_PERIOD					0x42
#define OFFS_ICESCINT_PIXELTRIGGERCOUNTER_RATE						0x30
#define SPAN_ICESCINT_PIXELTRIGGERCOUNTER_RATE						2
#define COUNT_ICESCINT_PIXELTRIGGERCOUNTER_RATE						8

#define OFFS_ICESCINT_READOUT_NUMBEROFSAMPLESTOREAD					0xa6
#define OFFS_ICESCINT_READOUT_READOUTMODE							0xaa

#define OFFS_ICESCINT_READOUT_SINGLESOFTTRIGGER						0xd2
// 8 bit rw register
//   bit 0 - channel 0
//   bit 1 - channel 1
//   ...
//   bit 7 - channel 7
#define OFFS_ICESCINT_READOUT_TRIGGERMASK							0xd4
#define OFFS_ICESCINT_READOUT_SOFTTRIGGERGENERATORENABLE			0xd8
#define OFFS_ICESCINT_READOUT_SOFTTRIGGERGENERATORPERIOD_LOW		0xda
#define OFFS_ICESCINT_READOUT_SOFTTRIGGERGENERATORPERIOD_HIGH		0xdc

#define OFFS_ICESCINT_READOUT_CORRECTIONRAMCHANNELMASK				0xe0
#define OFFS_ICESCINT_READOUT_CORRECTIONRAMADDRESS					0xe2
#define OFFS_ICESCINT_READOUT_CORRECTIONRAMWRITEVALUE				0xe4

#define OFFS_ICESCINT_IRQ_FIFO_EVENTCOUNT_THRESH	0x104	// threshold of event words in fifo, at which an IRQ is asserted
#define OFFS_ICESCINT_IRQ_CTRL						0x106	//
#define BIT_ICESCINT_IRQ_CTRL_IRQ_EN				0
#define OFFS_ICESCINT_IRQ_FORCE						0x108	// writing to this address generates a single IRQ, no matter if irq are enabled or not

#define OFFS_ICESCINT_READOUT_RS485DATA					0x300
#define OFFS_ICESCINT_READOUT_RS485DATASEND				0x310




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