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
#include <hal/icescint_panelGeneralPurposeBoard.hpp>

//using namespace std;
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
		("channel,c", po::value<int>(), "channel [0-7]")
		("setTriggerThreshold", po::value<int>(), "[0-255] applies to all channels if {channel} not used")
		("getTriggerThreshold", "for all channels if {channel} not used")
		("setSerdesDelay", po::value<int>(), "[0-1023]")
		("getSerdesDelay", "")
		("setDrs4ReadoutMode", po::value<int>(), "") // ## the spike thing...
		("getDrs4ReadoutMode", "")
		("setDrs4NumberOfSamplesToRead", po::value<int>(), "[10-1024] more than 1024 will reread old samples")
		("getDrs4NumberOfSamplesToRead", "")
		("setDebugDrs4Chip", po::value<int>(), "[0-2] debug: select DRS4 to take data from")
		("getDebugDrs4Chip", "")
		("setTriggerMask", po::value<std::string>(), "8 bit mask in hex, each bit corresponds to one channel, '1' will disable and '0' will enable the channel")
		("getTriggerMask", "in hex")
		("setPanelPower", po::value<int>(), "[0-1] needs {channel} (remember: the panel needs some time to boot)")
//		("getPanelPower", "")
		("setPanelPowerMask", po::value<std::string>(), "8 bit mask in hex, each bit corresponds to one channel, '1' will power on and '0' will power off a panel (remember: the panel needs some time to boot)")
		("getPanelPowerMask", "in hex")
		("setIrqEnable", po::value<int>(), "[0-1] interrupt from FPGA to ARM")
		("getIrqEnable", "")
		("setIrqAtFifoWords", po::value<int>(), "[1-8191] interrupt if fifo has more words")
		("getIrqAtFifoWords", "")
		("setIrqAtNumberOfEvents", po::value<int>(), "[0-8192] interrupt if number of events in fifo is greater")
		("getIrqAtNumberOfEvents", "")
		("setDrs4BaselineStart", po::value<int>(), "[0-1023] needs to be less than {setDrs4NumberOfSamplesToRead}")
		("getDrs4BaselineStart", "")
		("setDrs4BaselineStop", po::value<int>(), "[0-1023] needs to be less than {setDrs4NumberOfSamplesToRead}")
		("getDrs4BaselineStop", "")
		("setPixelRatePeriod", po::value<int>(), "[0-65535] in seconds, no counter reset if 0")
		("getPixelRatePeriod", "")
		("setPacketConfigMask", po::value<std::string>(), "each bit enables one type of packets in the main fifo")
		("getPacketConfigMask", "in hex")
		("setPacketDrs4Sampling", po::value<int>(), "[0-1] enables data type for fifo")
		("getPacketDrs4Sampling", "")
		("setPacketDrs4Baseline", po::value<int>(), "[0-1] enables data type for fifo")
		("getPacketDrs4Baseline", "")
		("setPacketDrs4Charge", po::value<int>(), "[0-1] enables data type for fifo")
		("getPacketDrs4Charge", "")
		("setPacketDrs4Cascading", po::value<int>(), "[0-1] enables data type for fifo")
		("getPacketDrs4Cascading", "")
//		("setPacketDrs4Timing", po::value<int>(), "[0-1] enables data type for fifo")
//		("getPacketDrs4Timing", "")
		("setPacketTriggerTiming", po::value<int>(), "[0-1] enables data type for fifo")
		("getPacketTriggerTiming", "")
		("setPacketWhiteRabbit", po::value<int>(), "[0-1] enables data type for fifo")
		("getPacketWhiteRabbit", "")
		("setPacketGps", po::value<int>(), "[0-1] enables data type for fifo")
		("getPacketGps", "")
		("setPacketPixelRates", po::value<int>(), "[0-1] enables data type for fifo")
		("getPacketPixelRates", "")
		("setPacketMisc", po::value<int>(), "[0-1] enables data type for misc data")
		("doPacketMisc", "send the misc packet once, immediately")
		("setSoftTriggerSingleShot", po::value<int>(), "no value")
		("setSoftTriggerGeneratorEnable", po::value<int>(), "[0,1]")
		("setSoftTriggerGeneratorPeriod", po::value<int>(), "[0-2^32] in ~8ns steps")
		("automaticConfiguration,x", "uses a fixed configuration")
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
		std::cout << "*** iceScintConfig - simple tool for command line based configuration | " << __DATE__ << " | " << __TIME__ << " ***" << std::endl;
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

	if(vm.count("triggermask"))
	{
		icescint_setTriggerMask(stringToInt(vm["triggermask"].as<std::string>()));
//		iceSint_setTriggerMask(vm["triggermask"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("channel"))
	{
		uint16_t temp = vm["channel"].as<int>();
		if((temp < 0) || (temp > ICESCINT_NUMBEROFCHANNELS-1)){std::cout << "value for 'channel' invalid (has to be 0-7)" << std::endl; return EXIT_ERROR;}
		else{channel = temp;}
	}

	if(vm.count("setTriggerThreshold"))
	{
		//if(!vm.count("channel")){std::cout << "'setTriggerTheshold' needs a 'channel'" << std::endl; return EXIT_ERROR;}
		if(!vm.count("channel"))
		{
			for(int i=0;i<8;i++)
			{
				icescint_setTriggerThreshold(i, vm["setTriggerThreshold"].as<int>());
			}
		}
		else
		{
			icescint_setTriggerThreshold(vm["channel"].as<int>(), vm["setTriggerThreshold"].as<int>());
		}
		return EXIT_OK;
	}
	if(vm.count("getTriggerThreshold"))
	{
		if(!vm.count("channel"))
		{
//			std::cout << "'getTriggerTheshold' needs a 'channel'" << std::endl;
//			return EXIT_ERROR;
			for(int i=0;i<8;i++)
			{
				std::cout << int(icescint_getTriggerThreshold(i)) << std::endl;
			}
		}
		else
		{
			std::cout << int(icescint_getTriggerThreshold(vm["channel"].as<int>())) << std::endl;
		}
		return EXIT_OK;
	}

	if(vm.count("setSerdesDelay"))
	{
		icescint_setSerdesDelay(vm["setSerdesDelay"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getSerdesDelay"))
	{
		std::cout << int(icescint_getSerdesDelay()) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setDrs4ReadoutMode"))
	{
		drs4_setDrs4ReadoutMode(vm["setDrs4ReadoutMode"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getDrs4ReadoutMode"))
	{
		std::cout << int(drs4_getDrs4ReadoutMode()) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setDrs4NumberOfSamplesToRead"))
	{
		drs4_setNumberOfSamplesToRead(vm["setDrs4NumberOfSamplesToRead"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getDrs4NumberOfSamplesToRead"))
	{
		std::cout << int(drs4_getNumberOfSamplesToRead()) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setDebugDrs4Chip"))
	{
		icescint_setDebugSetDrs4Chip(vm["setDebugDrs4Chip"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getDebugDrs4Chip"))
	{
		std::cout << int(icescint_getDebugSetDrs4Chip()) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setTriggerMask"))
	{
		icescint_setTriggerMask(stringToInt(vm["setTriggerMask"].as<std::string>()));
		return EXIT_OK;
	}
	if(vm.count("getTriggerMask"))
	{
		std::cout << std::hex << "0x" << int(icescint_getTriggerMask()) << std::dec << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPanelPowerMask"))
	{
		icescint_setPanelPowerMask(stringToInt(vm["setPanelPowerMask"].as<std::string>()));
		return EXIT_OK;
	}
	if(vm.count("getPanelPowerMask"))
	{
		std::cout << std::hex << "0x" << int(icescint_getPanelPowerMask()) << std::dec << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPanelPower"))
	{
		if(!vm.count("channel")){std::cout << "'setPanelPower' needs a 'channel'" << std::endl; return EXIT_ERROR;}
		icescint_setPanelPower(vm["channel"].as<int>(), vm["setPanelPower"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("setIrqEnable"))
	{
		icescint_setIrqEnable(vm["setIrqEnable"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getIrqEnable"))
	{
		std::cout << int(icescint_isIrqEnable()) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setIrqAtFifoWords"))
	{
		icescint_setIrqAtFifoWords(vm["setIrqAtFifoWords"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getIrqAtFifoWords"))
	{
		std::cout << int(icescint_getIrqAtFifoWords()) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setIrqAtNumberOfEvents"))
	{
		icescint_setIrqAtEventCount(vm["setIrqAtNumberOfEvents"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getIrqAtNumberOfEvents"))
	{
		std::cout << int(icescint_getIrqAtEventCount()) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPacketConfigMask"))
	{
		icescint_setEventFifoPacketConfig(stringToInt(vm["setPacketConfigMask"].as<std::string>()));
		return EXIT_OK;
	}
	if(vm.count("getPacketConfigMask"))
	{
		std::cout << std::hex << "0x" << int(icescint_getEventFifoPacketConfig()) << std::dec << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPacketDrs4Sampling"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4SAMPLING, vm["setPacketDrs4Sampling"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}
	if(vm.count("getPacketDrs4Sampling"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		std::cout << int(temp & MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4SAMPLING) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPacketDrs4Baseline"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4BASELINE, vm["setPacketDrs4Baseline"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}
	if(vm.count("getPacketDrs4Baseline"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		std::cout << ((temp & MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4BASELINE)?1:0) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPacketDrs4Charge"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4CHARGE, vm["setPacketDrs4Charge"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}
	if(vm.count("getPacketDrs4Charge"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		std::cout << ((temp & MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4CHARGE)?1:0) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPacketDrs4Timing"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4TIMING, vm["setPacketDrs4Timing"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}
	if(vm.count("getPacketDrs4Timing"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		std::cout << ((temp & MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4TIMING)?1:0) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPacketDrs4Cascading"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4CASCADING, vm["setPacketDrs4Cascading"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}
	if(vm.count("getPacketDrs4Cascading"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		std::cout << ((temp & MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4CASCADING)?1:0) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPacketTriggerTiming"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TRIGGERTIMING, vm["setPacketTriggerTiming"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}
	if(vm.count("getPacketTriggerTiming"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		std::cout << ((temp & MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TRIGGERTIMING)?1:0) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPacketWhiteRabbit"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_WHITERABBIT, vm["setPacketWhiteRabbit"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}
	if(vm.count("getPacketWhiteRabbit"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		std::cout << ((temp & MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_WHITERABBIT)?1:0) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPacketGps"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_GPS, vm["setPacketGps"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}
	if(vm.count("getPacketGps"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		std::cout << ((temp & MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_GPS)?1:0) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPacketPixelRates"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_PIXELRATES, vm["setPacketPixelRates"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}
	if(vm.count("getPacketPixelRates"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		std::cout << ((temp & MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_PIXELRATES)?1:0) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPacketMisc"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_MISC, vm["setPacketMisc"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}
	if(vm.count("getPacketMisc"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		std::cout << ((temp & MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_MISC)?1:0) << std::endl;
		return EXIT_OK;
	}
	if(vm.count("doPacketMisc"))
	{
		icescint_doForceMiscData();
		return EXIT_OK;
	}

	if(vm.count("setSoftTriggerSingleShot"))
	{
		icescint_doSingleSoftTrigger();
		return EXIT_OK;
	}

	if(vm.count("setSoftTriggerGeneratorEnable"))
	{
		icescint_setSoftTriggerGeneratorEnable(vm["setSoftTriggerGeneratorEnable"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("setSoftTriggerGeneratorPeriod"))
	{
		icescint_setSoftTriggerGeneratorPeriod(vm["setSoftTriggerGeneratorPeriod"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("setPixelRatePeriod"))
	{
		icescint_setPixelTriggerCounterPeriod(vm["setPixelRatePeriod"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getPixelRatePeriod"))
	{
		std::cout << int(icescint_getPixelTriggerCounterPeriod()) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setDrs4BaselineStart"))
	{
		icescint_setBaselineStart(vm["setDrs4BaselineStart"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getDrs4BaselineStart"))
	{
		std::cout << int(icescint_getBaselineStart()) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setDrs4BaselineStop"))
	{
		icescint_setBaselineStop(vm["setDrs4BaselineStop"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getDrs4BaselineStop"))
	{
		std::cout << int(icescint_getBaselineStop()) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("automaticConfiguration"))
	{
		for(int i=0;i<8;i++) {icescint_setTriggerThreshold(i, 50);}
		icescint_setSerdesDelay(100);
		drs4_setDrs4ReadoutMode(6);
		drs4_setNumberOfSamplesToRead(1024);
		icescint_setTriggerMask(0x00);
		icescint_setPanelPowerMask(0xff);
		icescint_setIrqAtFifoWords(4096);
		icescint_setIrqAtEventCount(100);
		icescint_setIrqEnable(1);
		icescint_setPixelTriggerCounterPeriod(1);

		icescint_setEventFifoPacketConfig( 0x0
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4SAMPLING
			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4BASELINE
			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4CHARGE
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4TIMING
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TRIGGERTIMING
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TEST_DATA1
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TEST_DATA2
			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_MISC
			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_WHITERABBIT
			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_GPS
			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_PIXELRATES
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DEBUG
			);
		icescint_setBaselineStart(0);
		icescint_setBaselineStop(10);
		icescint_setSoftTriggerGeneratorPeriod(0x8000000);
		icescint_setSoftTriggerGeneratorEnable(0);

		icescint_setRs485SoftTxMask(0x0);

		// baseline
		// -


		// panels
//		usleep(1000*6000);
//		for(int i=0;i<7;i++)
//		{
//			icescint_pannelPowerOn(i);
//		}
//		usleep(1000*100);
//
//		for(int i=0;i<7;i++)
//		{
//			icescint_pannelSwitchToLg(i);
//		}
//		usleep(1000*100);
//
//		for(int i=0;i<7;i++)
//		{
//			icescint_pannelSetSipmVoltage(i, 53.0);
//		}

		return EXIT_OK;
	}

	return EXIT_OK;
}
