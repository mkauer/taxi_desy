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
		("channel,c", po::value<int>(), "channel [0-15]")
		("setTriggerThreshold", po::value<int>(), "[0-255] needs {channel}")
		("incTriggerThreshold", "increase value by 1, needs {channel}")
		("decTriggerThreshold", "decrease value by 1, needs {channel}")
		("setPanelPowerTop", po::value<int>(), "[0-255] set HV value for top panel")
		("setPanelPowerBottom", po::value<int>(), "[0-255] set HV value for bottom panel")
		("setIrqEnable", po::value<int>(), "[0-1] interrupt from FPGA to ARM")
		("setIrqAtFifoWords", po::value<int>(), "[1-8191] interrupt if fifo has more words")
		("setIrqAtNumberOfEvents", po::value<int>(), "[0-8192] interrupt if number of events in fifo is greater")
		("setPixelRatePeriod", po::value<int>(), "[0-65535] in seconds, no counter reset if 0")
		("setPacketConfigMask", po::value<std::string>(), "each bit enables one type of packets in the main fifo")
		("setPacketGps", po::value<int>(), "[0-1] enables data type for fifo")
		("setPacketPixelRates", po::value<int>(), "[0-1] enables data type for fifo")
		("setPacketSectorRates", po::value<int>(), "[0-1] enables data type for fifo")
		("setPacketEventTiming", po::value<int>(), "[0-1] enables data type for fifo")
//		("setSoftTriggerSingleShot", po::value<int>(), "no value")
//		("setSoftTriggerGeneratorEnable", po::value<int>(), "[0,1]")
//		("setSoftTriggerGeneratorPeriod", po::value<int>(), "[0-2^32] in ~8ns steps")
		("defaultConfiguration,d", "uses the default configuration")
//		("printAutomaticConfiguration,y", po::value<int>(), "print the fixed configuration")
//		("programmFpga,z", po::value<int>(), "reloads the FPGA with a fixed version (does not use the defaultFirmware.bit)")
//		("", po::value<int>(), "")
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

	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
	po::notify(vm);

	if (vm.count("help"))
	{
		std::cout << "*** polarstern_config - simple tool for command line based configuration | " << __DATE__ << " | " << __TIME__ << " ***" << std::endl;
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

	// boot fpga

	// automaticConfig

	if(vm.count("channel"))
	{
		uint16_t temp = vm["channel"].as<int>();
		if((temp < 0) || (temp > POLARSTERN_NUMBEROFCHANNELS-1)){std::cout << "value for 'channel' invalid (has to be 0-15)" << std::endl; return EXIT_ERROR;}
		else{channel = temp;}
	}

	if(vm.count("setTriggerThreshold"))
	{
		if(!vm.count("channel")){std::cout << "'setTriggerTheshold' needs a 'channel'" << std::endl; return EXIT_ERROR;}
		polarstern_setTriggerThreshold(vm["channel"].as<int>(), vm["setTriggerThreshold"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("incTriggerThreshold"))
	{
		if(!vm.count("channel")){std::cout << "'setTriggerTheshold' needs a 'channel'" << std::endl; return EXIT_ERROR;}
		uint16_t value = polarstern_getTriggerThreshold(vm["channel"].as<int>());
		if(value < 0xff) {value++;}
		polarstern_setTriggerThreshold(vm["channel"].as<int>(), value);
		return EXIT_OK;
	}

	if(vm.count("decTriggerThreshold"))
	{
		if(!vm.count("channel")){std::cout << "'setTriggerTheshold' needs a 'channel'" << std::endl; return EXIT_ERROR;}
		uint16_t value = polarstern_getTriggerThreshold(vm["channel"].as<int>());
		if(value > 0) {value--;}
		polarstern_setTriggerThreshold(vm["channel"].as<int>(), value);
		return EXIT_OK;
	}

	if(vm.count("setPanelPowerTop"))
	{
		polarstern_setPanelHv(0, vm["setPanelPowerTop"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("setPanelPowerBottom"))
	{
		polarstern_setPanelHv(1, vm["setPanelPowerBottom"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("setIrqEnable"))
	{
		polarstern_setIrqEnable(vm["setIrqEnable"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("setIrqAtFifoWords"))
	{
		polarstern_setIrqAtFifoWords(vm["setIrqAtFifoWords"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("setIrqAtNumberOfEvents"))
	{
		polarstern_setIrqAtEventCount(vm["setIrqAtNumberOfEvents"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("setPacketConfigMask"))
	{
		polarstern_setEventFifoPacketConfig(stringToInt(vm["setPacketConfigMask"].as<std::string>()));
		return EXIT_OK;
	}

	if(vm.count("setPacketSectorRates"))
	{
		uint16_t temp = polarstern_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_POLARSTERN_READOUT_EVENTFIFOPACKETCONFIG_SECTORRATES, vm["setPacketSectorRates"].as<int>());
		polarstern_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}

	if(vm.count("setPacketGps"))
	{
		uint16_t temp = polarstern_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_POLARSTERN_READOUT_EVENTFIFOPACKETCONFIG_GPS, vm["setPacketGps"].as<int>());
		polarstern_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}

	if(vm.count("setPacketPixelRates"))
	{
		uint16_t temp = polarstern_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_POLARSTERN_READOUT_EVENTFIFOPACKETCONFIG_PIXELRATES, vm["setPacketPixelRates"].as<int>());
		polarstern_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}

	if(vm.count("setPacketEventTiming"))
	{
		uint16_t temp = polarstern_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_POLARSTERN_READOUT_EVENTFIFOPACKETCONFIG_EVENTDATA, vm["setPacketEventTiming"].as<int>());
		polarstern_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}

	if(vm.count("setPixelRatePeriod"))
	{
		polarstern_setPixelTriggerCounterPeriod(vm["setPixelRatePeriod"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("defaultConfiguration"))
	{
		uint16_t thresholds[POLARSTERN_NUMBEROFCHANNELS] = {43,62,32,65,65,57,51,54,95,74,61,51,74,73,66,57};
		for(int i=0;i<(POLARSTERN_NUMBEROFCHANNELS);i++) {polarstern_setTriggerThreshold(i, thresholds[i]);}

		//polarstern_setAllTriggerThreshold(50);
		polarstern_setPanelHv(0, 0xf5);
		polarstern_setPanelHv(1, 0xf5);
		polarstern_setIrqAtFifoWords(4096);
		polarstern_setIrqAtEventCount(500);
		polarstern_setIrqEnable(1);
		polarstern_setPixelTriggerCounterPeriod(1);
		polarstern_doResetPixelTriggerCounterAndTime();

		polarstern_doResetPixelTriggerCounter();

		common_doFlushEventFifo();

		polarstern_setEventFifoPacketConfig( 0x0
			| MASK_POLARSTERN_READOUT_EVENTFIFOPACKETCONFIG_GPS
			| MASK_POLARSTERN_READOUT_EVENTFIFOPACKETCONFIG_PIXELRATES
			| MASK_POLARSTERN_READOUT_EVENTFIFOPACKETCONFIG_SECTORRATES
			| MASK_POLARSTERN_READOUT_EVENTFIFOPACKETCONFIG_EVENTDATA
			);

		return EXIT_OK;
	}

	return EXIT_OK;
}
