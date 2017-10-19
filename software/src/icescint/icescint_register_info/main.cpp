/*
 * I4Tui.cpp
 *
 *  Created on: Jan 17, 2013
 *      Author: kossatz
 */

#include <hal/icescint_defines.h>
#include <signal.h>
#include <sstream>
#include <string>
#include <iostream>
#include <algorithm>
#include <ctime>
#include <string.h>
#include "boost/program_options.hpp"
//#include "tools/types.h"
#include "hal/smc.h"
#include "hal/daqdrv.h"
#include "hal/bits.h"
#include "common/SimpleCurses.hpp"

using namespace sc;

typedef unsigned int addr_t;


void printRegister(Table& t, addr_t base, const char* _name)
{
	uint16_t value=IORD_16DIRECT(base, 0);
	setFg(cyan);
	printf("0x%x",base);
	t.nextColumn();
	setFg(white,true);
	printf("%s",_name);
	t.nextColumn();
	setFg(yellow);
	printf("0x%x",value);
	t.nextColumn();
	setFg(yellow);
	printf("%d",value);
	t.nextColumn();
}

void printValue(Table& t, const char* _name, int value)
{
	t.nextColumn();
	setFg(white,true);
	printf("%s",_name);
	t.nextColumn();
	setFg(yellow);
	printf("0x%x",value);
	t.nextColumn();
	setFg(yellow);
	printf("%d",value);
	t.nextColumn();
}


void printBit(Table& t, addr_t base, int bit, const char* _name)
{
	uint16_t value=IORD_16DIRECT(base, 0);
	setFg(cyan);
	printf("  %d",bit);
	t.nextColumn();
	setFg(white);
	printf("%s",_name);
	t.nextColumn();
	setFg(green);
	printf("%s",testBitVal16(value,bit)?"1":"0");
	t.nextColumn();
}

void printMask(Table& t, addr_t base, int bitmask, const char* _name)
{
	uint16_t value=IORD_16DIRECT(base, 0);
	setFg(cyan);
	printf(" 0x%x",bitmask);
	t.nextColumn();
	setFg(white);
	printf("%s",_name);
	t.nextColumn();
	setFg(green);
	printf("%s",(value&bitmask)?"yes":"no");
	t.nextColumn();
}


void printRegister()
{
	Table t(1,1);
	t.addColumn(7);
	t.addColumn(25);
	t.addColumn(8);
	t.addColumn(10);

	addr_t base=BASE_ICESCINT_READOUT;

#define __ROW(NAME, ADDRESS) 	t.nextRow(); \
		printRegister(t, base + ADDRESS, NAME);

#define __RBIT(NAME, ADDRESS, BIT) 	t.nextRow(); \
		printBit(t, base + ADDRESS, BIT, NAME);

#define __RMASK(NAME, ADDRESS, MASK) 	t.nextRow(); \
		printMask(t, base + ADDRESS, MASK, NAME);

	__ROW("fifo packet config", 	OFFS_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG);
	__RMASK("DRS4TIMING", 	OFFS_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG, VALUE_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4TIMING);
	__RMASK("DRS4CHARGE", 	OFFS_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG, VALUE_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4CHARGE);
	__RMASK("DRS4SAMPLING", OFFS_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG, VALUE_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4SAMPLING);
	__RMASK("DEBUG", 		OFFS_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG, VALUE_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DEBUG);
	__RMASK("TEST DATA", 	OFFS_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG, VALUE_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TEST_DATA);

	__ROW("number of samples", 		OFFS_ICESCINT_READOUT_NUMBEROFSAMPLESTOREAD);
	__ROW("trigger mask", 	OFFS_ICESCINT_READOUT_TRIGGERMASK);
	__ROW("soft trigger generator en", 		OFFS_ICESCINT_READOUT_SOFTTRIGGERGENERATORENABLE);
	__ROW("generator period low",	OFFS_ICESCINT_READOUT_SOFTTRIGGERGENERATORPERIOD_LOW);
	__ROW("generator period high",	OFFS_ICESCINT_READOUT_SOFTTRIGGERGENERATORPERIOD_HIGH);
	__ROW("fifo eventcount thresh",	OFFS_ICESCINT_IRQ_FIFO_EVENTCOUNT_THRESH);
	__ROW("fifo control",	OFFS_ICESCINT_IRQ_CTRL);
	__RBIT("irq enabled", 	OFFS_ICESCINT_IRQ_CTRL, BIT_ICESCINT_IRQ_CTRL_IRQ_EN);

}

void printDaqDriver()
{
	Table t(1,15);
	t.addColumn(7);
	t.addColumn(30);
	t.addColumn(8);
	t.addColumn(10);

	{
		t.nextRow();
		size_t offset=daqdrv_getWrOffset();
		printValue(t,	"daqdrv ringbuf wr pos", offset);
	}

}
/* This flag controls termination of the main loop. */
volatile sig_atomic_t keep_going = 1;

/* The signal handler just clears the flag and re-enables itself. */
void catch_signal (int sig) {
  keep_going = 0;
}

int main(int argc, char** argv)
{
	using namespace std;

	clear();
/*
	// catch signals
	struct sigaction sigact;
	sigact.sa_handler = catch_signal;
	sigemptyset(&sigact.sa_mask);
	sigact.sa_flags = 0;
//	sigaction(SIGINT, &sigact, NULL);
//	sigaction(SIGTERM, &sigact, NULL);
//	sigaction(SIGHUP, &sigact, NULL);
 * */


 	while(1) {

		int ret = smc_open(NULL);

		if(ret != ERROR_NONE)
		{
			clear();
			movexy(10,10);
			setFg(red,true);
			cout << "bus open error: " << int(ret) << endl;
			sleep(1);
			continue;
		}

		daqdrv_error_t ret2 = daqdrv_open(NULL);

		if(ret2 != DAQDRV_ERROR_NONE)
		{
			clear();
			movexy(10,10);
			setFg(red,true);
			cout << "daq driver open error: " << int(ret) << endl;
			sleep(1);
			continue;
		}

		printRegister();
		printDaqDriver();

		smc_close();

		daqdrv_close();

		printf("\n"); // flush
		//done();
		sleep(1);
	}

	return 0;
}
