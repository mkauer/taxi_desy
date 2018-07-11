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

#include <hal/polarstern.h>

#include "common/SimpleCurses.hpp"

//using namespace std;
namespace po = boost::program_options;

#define EXIT_OK 0
#define EXIT_ERROR -1

char g_statas[16];

void getStats(uint16_t *_threshold, uint16_t *_rate)
{
	for(int i=0;i<(POLARSTERN_NUMBEROFCHANNELS);i++)
	{
		*(_threshold+i) = polarstern_getTriggerThreshold(i);
		*(_rate+i) = polarstern_getPixelTriggerRates(i);
	}
	polarstern_doResetRatesNewData();
}

void printStats(void)
{
	sc::movexy(0,0);
	std::cout << "counter will reset every " << int(polarstern_getPixelTriggerCounterPeriod()) << " secounds                    " << std::endl << "--------------------------------------" <<std::endl;
	for(int i=0;i<(POLARSTERN_NUMBEROFCHANNELS);i++) {std::cout << "ch. \t" << i << ": " << "(" << int(polarstern_getTriggerThreshold(i)) << ")" << g_statas[i] << "\t" << int(polarstern_getPixelTriggerRates(i)) << "    " << std::endl;}
	polarstern_doResetRatesNewData();
}

int main(int argc, char** argv)
{
	int channel = -1;
	int period = 0;

	po::options_description desc("Allowed options");
	desc.add_options()
		("help,h", "")
		("printRates,p", "")
		("period,t", po::value<int>(), "time in [sec]")
		("tuneRatesTo,r", po::value<int>(), "[0-65535] rate in Hz")
		;

//	po::variables_map vm;
//	try
//	{
//		po::store(po::command_line_parser(argc, argv).options(desc).allow_unregistered().run(), vm);
//	}
//	catch (boost::program_options::invalid_command_line_syntax &e)
//	{
//		std::cerr << "error parsing command line: " << e.what() << std::endl;
//		std::cout << "error parsing command line: " << e.what() << std::endl;
//		return EXIT_ERROR;
//	}
//	po::notify(vm);

	for(int i=0;i<(POLARSTERN_NUMBEROFCHANNELS);i++) {g_statas[i] = ' ';}

	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
	po::notify(vm);

	if (vm.count("help"))
	{
		std::cout << "*** polarstern_rates - simple tool to display trigger rates | " << __DATE__ << " | " << __TIME__ << " ***" << std::endl;
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

	if (vm.count("printRates"))
	{
		sc::clear();

		while(1)
		{
			if(polarstern_isRatesNewData())
			{
				printStats();
			}
			else
			{
				usleep(1000*100);
			}
		}
	}

	if(vm.count("period")){period = vm["period"].as<int>();polarstern_setPixelTriggerCounterPeriod(period);}
	else {period = polarstern_getPixelTriggerCounterPeriod();}

	if (vm.count("tuneRatesTo"))
	{
		sc::clear();
		//polarstern_setAllTriggerThreshold(0x80);
		//polarstern_setPixelTriggerCounterPeriod(vm["period"].as<int>());
		polarstern_doResetPixelTriggerCounterAndTime();

		while(1)
		{
			if(polarstern_isRatesNewData())
			{
				printStats();
				for(int i=0;i<(POLARSTERN_NUMBEROFCHANNELS);i++)
				{
					if((polarstern_getPixelTriggerRates(i) / period) > (vm["tuneRatesTo"].as<int>()+vm["tuneRatesTo"].as<int>()/10))
					{
						uint16_t value = polarstern_getTriggerThreshold(i);
						if(value < 0xff) {value++; g_statas[i] = '+';}
						polarstern_setTriggerThreshold(i, value);
					}
					else if((polarstern_getPixelTriggerRates(i) / period) < (vm["tuneRatesTo"].as<int>()-vm["tuneRatesTo"].as<int>()/10))
					{
						uint16_t value = polarstern_getTriggerThreshold(i);
						if(value > 0) {value--; g_statas[i] = '-';}
						polarstern_setTriggerThreshold(i, value);
					}
					else
					{
						g_statas[i] = ' ';
					}
				}
			}
			else
			{
				usleep(1000*100);
			}
		}
	}

	return EXIT_OK;
}
