#include <boost/program_options.hpp>
#include <iostream>
#include  <iomanip>
#include <string.h>
#include "hal/smc.h"

#define BASE_TAXI_READOUT						0x0000
#define OFFS_TAXI_READOUT_EVENTFIFO				0x20
#define OFFS_TAXI_READOUT_EVENTFIFOWORDCOUNT	0x22

namespace po = boost::program_options;

// read data one-by-one directly from fifo, bypass the driver completly and irq
void readAndPrintEventsDirect(int numEvents=2000)
{
	for(int ev=0;ev<numEvents;ev++)
	{
		int words;
		for (int j=0;j<10;j++) {
			words = IORD_32DIRECT(BASE_TAXI_READOUT , OFFS_TAXI_READOUT_EVENTFIFOWORDCOUNT);
			if (words==0) {
				usleep(100000);
				continue;
			} break;
		}
		if (words==0) {
			std::cerr << "no data in fifo" << std::endl;
			break;
		}
		std::cout << std::dec << ev << ".event: ";
		std::cout << "(fifo words: " << std::dec << words << ") [";

		if (words>0) {
			for(int i=0;i<32;i++) {
				int data=IORD_16DIRECT(BASE_TAXI_READOUT , OFFS_TAXI_READOUT_EVENTFIFO);
				std::cout << "" <<  std::setfill('0') << std::setw(4) << std::hex << data << " ";
			}
		} else {
//			sleep(1);
		}

		std::cout << "]" << std::endl;
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

	if (vm.count("initialize")) {

		std::cout << "performing initialization" << std::endl;

//	    IOWR_16DIRECT(0x00,0x00, 0x00);
//	    usleep(sleep_after_write);
//	    IOWR_16DIRECT(0x00,0x22, 0xf);     // Set PTR offset to x15.
//	    usleep(sleep_after_write);
//
//	    // Paddle 1
//
//	    IOWR_16DIRECT(0x00,0x00, 0x11);      // Set Paddle 1 discriminators -- TAXI
//	//    IOWR_16DIRECT(0x00,0x00, 0x1177);    // Turn auto tune on.
//	//    usleep(sleep_after_write);
//
//	    IOWR_16DIRECT(0x00, 0x04, 0x01);	// Set comparator threshold
//	    usleep(sleep_after_write);
//	    IOWR_16DIRECT(0x00, 0x04, 0x101);	// Set comparator threshold
//	    usleep(sleep_after_write);
//	    IOWR_16DIRECT(0x00, 0x04, 0x201);	// Set comparator threshold
//	    usleep(sleep_after_write);
//	    IOWR_16DIRECT(0x00, 0x04, 0x301);	// Set comparator threshold
//	    usleep(sleep_after_write);
//	    IOWR_16DIRECT(0x00, 0x04, 0x401);	// Set comparator threshold
//	    usleep(sleep_after_write);
//	    IOWR_16DIRECT(0x00, 0x04, 0x501);	// Set comparator threshold
//	    usleep(sleep_after_write);
//	    IOWR_16DIRECT(0x00, 0x04, 0x601);	// Set comparator threshold
//	    usleep(sleep_after_write);
//	    IOWR_16DIRECT(0x00, 0x04, 0x701);	// Set comparator threshold
//	    usleep(sleep_after_write);
//
//	    IOWR_16DIRECT(0x00, 0x08, 0x7F1);        // Set PMT voltage to 800 V. -- TAXI
//	    usleep(sleep_after_write);
//	    //IOWR_16DIRECT(0x00, 0x08, 0x17F1);       // Set PMT voltage to 800 V. -- TAXI
//	    IOWR_16DIRECT(0x00, 0x08, 0x17F1);       // Set PMT voltage to 800 V. -- TAXI
//	    usleep(sleep_after_write);
//
//	    IOWR_16DIRECT(0x00,0x00, 0x1411);     // System enable triggering and power.

		int cal_mode_ = 0;
		int pmt_hv_ = 0;
		int dscr_thr0_ = 10;

		IOWR_16DIRECT(0x00,0x00, 0x00);
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00,0x22, 0xf);     // Set PTR offset to x15.
		usleep(sleep_after_write);

		// Paddle 1

		IOWR_16DIRECT(0x00,0x00, 0x11);      // Set Paddle 1 discriminators -- TAXI

		usleep(sleep_after_write);

		//    IOWR_16DIRECT(0x00,0x00, 0x1177);    // Turn auto tune on.
		//    usleep(sleep_after_write);


		// 07/26 -> polar stern thres x20 and taxi x18
		IOWR_16DIRECT(0x00, 0x04, (0x0 << 8) | dscr_thr0_);	        // Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x1 << 8) | dscr_thr0_);	        // Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x2 << 8) | dscr_thr0_);	        // Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x3 << 8) | dscr_thr0_);	        // Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x4 << 8) | dscr_thr0_);	        // Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x5 << 8) | dscr_thr0_);	        // Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x6 << 8) | dscr_thr0_);	        // Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x7 << 8) | dscr_thr0_);	        // Set comparator threshold
		usleep(sleep_after_write);
		/*
		//Paddle 2

		IOWR_16DIRECT(0x00,0x00, 0x23);  // Set Paddle 2 discriminators -- TAXI
		usleep(sleep_after_write);

		//    IOWR_16DIRECT(0x00,0x00, 0x1177);    // Turn auto tune on.
		//    usleep(sleep_after_write);


		// 07/26 -> polar stern thres x40 and taxi x24
		IOWR_16DIRECT(0x00, 0x04, (0x0 << 8) | dscr_thr8_);	        // Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x1 << 8) | dscr_thr9_);	        // Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x2 << 8) | dscr_thr10_);	// Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x3 << 8) | dscr_thr11_);	// Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x4 << 8) | dscr_thr12_);	// Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x5 << 8) | dscr_thr13_);	// Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x6 << 8) | dscr_thr14_);	// Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x7 << 8) | dscr_thr15_);	// Set comparator threshold
		usleep(sleep_after_write);

		//Paddle 3

		//this paddle does not exist for Polar Stern
		IOWR_16DIRECT(0x00,0x00, 0x47);  // Set Paddle 3 discriminators -- TAXI
		usleep(sleep_after_write);

		//    IOWR_16DIRECT(0x00,0x00, 0x1177);    // Turn auto tune on.
		//    usleep(sleep_after_write);


		// 07/26 -> polar stern thres x40 and taxi x24
		IOWR_16DIRECT(0x00, 0x04, (0x0 << 8) | dscr_thr16_);	// Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x1 << 8) | dscr_thr17_);	// Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x2 << 8) | dscr_thr18_);	// Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x3 << 8) | dscr_thr19_);	// Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x4 << 8) | dscr_thr20_);	// Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x5 << 8) | dscr_thr21_);	// Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x6 << 8) | dscr_thr22_);	// Set comparator threshold
		usleep(sleep_after_write);
		IOWR_16DIRECT(0x00, 0x04, (0x7 << 8) | dscr_thr23_);	// Set comparator threshold
		usleep(sleep_after_write);
		//
		*/
		// Enable triggering
		// SVA

		//IOWR_16DIRECT(0x00, 0x00, 0x77);         // System enable triggering and power. --TAXI
		IOWR_16DIRECT(0x00, 0x00, 0x11);         // System enable triggering and power for only bank 1. --SVA
		usleep(sleep_after_write);
		//IOWR_16DIRECT(0x00, 0x08, 0x7F1);        // Set PMT voltage to 800 V. -- TAXI
		IOWR_16DIRECT(0x00, 0x08, pmt_hv_);        // Set PMT voltage to 800 V. -- TAXI
		usleep(sleep_after_write);
		//IOWR_16DIRECT(0x00, 0x08, 0x17F1);       // Set PMT voltage to 800 V. -- TAXI
		IOWR_16DIRECT(0x00, 0x08, (0x1 << 12) | pmt_hv_);       // Set PMT voltage to 800 V. -- TAXI
		usleep(sleep_after_write);
		if (cal_mode_ == 0){
		//    IOWR_16DIRECT(0x00,0x00, 0x477);    // System enable triggering and power. --TAXI
			IOWR_16DIRECT(0x00,0x00, 0x1411);    // System enable triggering and power for only bank 1. --SVA
		}
		else {
			 IOWR_16DIRECT(0x00,0x30, 0x1400);     // System enable triggering and power. --TAXI
			 usleep(sleep_after_write);
			 IOWR_16DIRECT(0x00,0x30, 0x2400);     // System enable triggering and power. --TAXI
			 usleep(sleep_after_write);
			 IOWR_16DIRECT(0x00,0x30, 0x3400);     // System enable triggering and power. --TAXI
			 usleep(sleep_after_write);
		//    IOWR_16DIRECT(0x00,0x00, 0x1E77);     // System enable triggering and power. --TAXI
			 IOWR_16DIRECT(0x00,0x00, 0x1E11);     // System enable triggering and power for only bank 1. --SVA
			 usleep(sleep_after_write);
		//     IOWR_16DIRECT(0x00,0x00, 0x677);     // System enable triggering and power. --TAXI

			 IOWR_16DIRECT(0x00,0x30, 0x1400);     // System enable triggering and power. --TAXI --dummy
			 usleep(sleep_after_write);
		}



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
