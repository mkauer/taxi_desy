/*
 *
 *  author :
 *
 */
#include <csignal>
#include <iostream>
#include <fstream>
#include <set>
#include <sstream>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <boost/functional.hpp>
#include <boost/program_options.hpp>
#include <boost/thread.hpp>

#include <hal/uvlogger.h>
#include <hal/icescint.h>

namespace po = boost::program_options;

#define EXIT_OK 0
#define EXIT_ERROR -1

int main(int argc, char** argv)
{
	int period = 0;

	po::options_description desc("Allowed options");
	desc.add_options()
		("help,h", "")
		;

	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
	po::notify(vm);

	if (vm.count("help"))
	{
		std::cout << "*** uvlogger_rates - simple tool for command line based trigger rate display | " << __DATE__ << " | " << __TIME__ << " ***" << std::endl;
		std::cout << desc << std::endl;
		//std::cout << "all masks are hex, other values are decimal" << std::endl;
		return EXIT_OK;
	}

	smc_driver_error_t err;
	err = smc_open(0);
	if (err != ERROR_NONE)
	{
		std::cerr << "cannot open bus driver!" << std::endl;
		return EXIT_ERROR;
	}

	int i = 0;
	char hb[] = {'|','/','-','\\'};
	int gateTime = 0;

//-----------------------------------------------------------------------------

	while(1)
	{
		if(icescint_isTriggerRateNewData())
		{
			gateTime = SYSTEMTICKTIME_NS * uvlogger_getRateCounterGateTime();
			printf("\033[2J"); // clear screen
			printf("\033[H"); // cursor to upper left corner
			period = icescint_getPixelTriggerCounterPeriod();
			if((period == 0xffff) || (period == 0xdead)) {usleep(1000*1000);} // avoid some of the spam
			std::cout << "  trigger rate per " << period << " sec. (gate time ~" << gateTime << "ns)" << std::endl << std::endl;
			std::cout << "                              " << std::endl;
			std::cout << "all rising edges              " << std::endl;
			std::cout << "------------------------------" << std::endl;
			for(int i=0;i<COUNT_ICESCINT_PIXELTRIGGERCOUNTER_RATE;i++)
			{
				std::cout << "ch." << i << ": " << int(uvlogger_getPixelTriggerAllRisingEdgesRate(i)) << std::endl;
			}

			printf("\033[%d;20H",3);
			std::cout << "|first rising edges " << std::endl;
			printf("\033[%d;20H",4);
			std::cout << "|during gate        " << std::endl;
			printf("\033[%d;20H",5);
			std::cout << "+-------------------" << std::endl;
			for(int i=0;i<COUNT_ICESCINT_PIXELTRIGGERCOUNTER_RATE;i++)
			{
				printf("\033[%d;20H",i+6);
				std::cout << "|ch." << i << ": " << int(uvlogger_getPixelTriggerFirstHitsDuringGateRate(i)) << std::endl;
			}

			printf("\033[%d;40H",3);
			std::cout << "|additional rising  " << std::endl;
			printf("\033[%d;40H",4);
			std::cout << "|edges during gate  " << std::endl;
			printf("\033[%d;40H",5);
			std::cout << "+-------------------" << std::endl;
			for(int i=0;i<COUNT_ICESCINT_PIXELTRIGGERCOUNTER_RATE;i++)
			{
				printf("\033[%d;40H",i+6);
				std::cout << "|ch." << i << ": " << int(uvlogger_getPixelTriggerAdditionalHitsDuringGateRate(i)) << std::endl;
			}
			icescint_doTriggerRateNewDataReset(1);
		}
		else
		{
			printf("\033[H"); // cursor to upper left corner
			std::cout << hb[i] << std::endl;
			printf("\033[H"); // cursor to upper left corner
			usleep(100*1000);
		}
		i=(i+1)%sizeof(hb);
	}


	return EXIT_OK;
}
