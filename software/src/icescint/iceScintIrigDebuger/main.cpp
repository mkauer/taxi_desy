/*
 *  Log data receiver & broadcaster
 *  author : giavitto
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

#include <hal/icescint.h>

#include <bitset>
#include <boost/algorithm/string/replace.hpp>

namespace po = boost::program_options;

#define EXIT_OK 0
#define EXIT_ERROR -1

//---------------------------------------------

int stringToInt(std::string _string)
{
	int temp;
	std::stringstream interpreter;
	interpreter << std::hex << _string;
	interpreter >> temp;

	return temp;
}

int main(int argc, char** argv)
{
	int channel = -1;

	po::options_description desc("Allowed options");
	desc.add_options()
		("help,h", "")
//		("", po::value<int>(), "")
		;

	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
	po::notify(vm);

	if (vm.count("help"))
	{
		std::cout << "*** iceScintDebugger | " << __DATE__ << " | " << __TIME__ << " ***" << std::endl;
		std::cout << desc << std::endl;
		std::cout << "all masks are hex, other values are decimal" << std::endl;
		return EXIT_OK;
	}

	smc_driver_error_t err;
	err = smc_open(0);
	if (err != ERROR_NONE)
	{
		std::cerr << "cannot open bus driver!" << std::endl;
		return EXIT_ERROR;
	}

	uint16_t data[10] = {1,2,3,4,5,6,7,8,9,0};

	while(1)
	{
		if(icescint_isNewIrigData())
		{
			icescint_getIrigRawData(data);
			for(int i=5;i>=0;i--)
			{
				for(int j=15;j>=0;j--)
				{
					if((*(data+i) & (1<<j)) == 0) {std::cout << ".";}
					else {std::cout << "1";}
				}
				std::cout << "|";
			}
			std::cout << std::endl;

			std::cout << std::dec;
			std::cout << "irigb binary year: " << std::dec << int(icescint_getIrigBinaryYear()) << std::endl;
			std::cout << "irigb binary day: " << std::dec << int(icescint_getIrigBinaryDay()) << std::endl;
			std::cout << "irigb binary second: " << std::dec << int(icescint_getIrigBinarySecond()) << std::endl;

			icescint_doResetNewIrigData();
		}

		if(icescint_isNewGpsData())
		{
			std::cout << std::dec;
			std::cout << "GPS week: " << int(icescint_getGpsWeek()) << std::endl;
			std::cout << "GPS QuantizationError: " << int(icescint_getGpsQuantizationError()) << std::endl;
			std::cout << "GPS time of week ms: " << int(icescint_getGpsTimeOfWeek_ms()) << std::endl;
			std::cout << "GPS time of week sub ms: " << int(icescint_getGpsTimeOfWeek_subms()) << std::endl;

			icescint_doResetNewGpsData();
		}

		usleep(1000*100);
	}



	return EXIT_OK;
}
