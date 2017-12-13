#include <boost/program_options.hpp>
#include <iostream>
#include  <iomanip>
#include <string.h>
#include "hal/smc.h"
#include "hal/daqdrv.h"
#include "common/icescint_validator.hpp"
#include "hal/icescint.h"

namespace po = boost::program_options;

int verbose=0;

/*
0)	b000 - header für testdaten

    c000 x x+1 x+2 x+3 x+4 x+5 x+6 x+7

    c001

    c002

     ...

    c3ff

1)
2)
3)
4)
5)
6)
7)
8)

fifoEventWord = sample = 18 bytes block

*/




// read data one-by-one directly from fifo, bypass the driver completly and irq
void readAndPrintEventsDirect(int numEvents=2000)
{

	TestDataValidator validator;

	for(int ev=0;ev<numEvents;ev++)
	{

		daqdrv_error_t err=daqdrv_waitForIrq(5000);

		if (err==DAQDRV_ERROR_NONE) {
		   if (verbose>1) std::cout << "got irq!" << std::endl;

			size_t size;
			void* data;
			do {
				size=daqdrv_getData(&data);

				validator.process(data, size);

			} while (1);
		}
	}

	return ;
}

int main(int argc, char** argv)
{
//    const useconds_t sleep_after_write = 1000000; // 1s
    const useconds_t sleep_after_write = 100000; // 0,1s

	bool testData=false;
	int eventsPerIrq;
	int period;
	int samples;
	std::string mode;
	std::string server;
	int port;
	int count = 2000;

	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
			("initialize,i","")
			("count,c", po::value<std::string>(), "read c counts from the fifo")
			("verbose,v", po::value<int>(&verbose)->default_value(0), "set verbosity 0=none, 1=little, 2=full")
	;

	po::variables_map vm;
	try
	{
		po::store(po::command_line_parser(argc, argv).options(desc).allow_unregistered().run(), vm);
	}
	catch (boost::program_options::invalid_command_line_syntax &e)
	{
		std::cerr << "error parsing command line: " << e.what() << std::endl;
		return 1;
	}
	po::notify(vm);

	if (vm.count("help"))
	{
		std::cout << "description: runs tests with the test generator to test irq, fifo and network sending"  << std::endl << "(compiled " << __DATE__ << " " << __TIME__ << ")" << std::endl << desc << std::endl;
		return 1;
	}

	smc_driver_error_t err;

	err = smc_open(0);
	if (err!=ERROR_NONE) {
		std::cerr << "cannot open bus driver!" << std::endl;
		return 1;
	}

	daqdrv_error_t derr;

	derr = daqdrv_open(0);
	if (derr!=DAQDRV_ERROR_NONE) {
		std::cerr << "cannot open daqdrv!" << std::endl;
		return 1;
	}

	if (vm.count("initialize")) {

		std::cout << "performing initialization" << std::endl;

		IOWR_16DIRECT(0x106,0x00, 0x00); // interrupt disable

		daqdrv_clearBuffers();

		IOWR_16DIRECT(0xda,0x00, 0x00);

		IOWR_16DIRECT(0xdc,0x00, 0x800);

		IOWR_16DIRECT(0xd8,0x00, 0x01); // generator enable

		// IOWR_16DIRECT(0x108,0x00, 0x01); // force interrupt, works anytime, ignores irq enable

		IOWR_16DIRECT(0x102,0x00, 0x01); // event / interrupt

		IOWR_16DIRECT(0x104,0x00, 0x01); // irq at eventfifoword count (1 eventfifoword 182 bytes)

		icescint_setEventFifoPacketConfig(MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DEBUG);

		IOWR_16DIRECT(0x106,0x00, 0x01); // interrupt enable

		return 0;
	}

	if (vm.count("count")) {
		std::stringstream interpreter;
		interpreter << std::dec << vm["count"].as<std::string>();
		interpreter >> count;
	}

	readAndPrintEventsDirect(count);

	return 0;
}
