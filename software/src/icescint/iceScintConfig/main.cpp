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
		("setTriggerTheshold", po::value<int>(), "[0-255] needs {channel}")
		("setSerdesDelay", po::value<int>(), "[0-1024]")
		("setDrs4ReadoutMode", po::value<int>(), "") // ## the spike thing...
		("setDrs4NumberOfSamplesToRead", po::value<int>(), "[10-1024] more than 1024 will reread old samples")
		("setTriggerMask", po::value<std::string>(), "8 bit mask in hex, each bit corresponds to one channel")
		("setPanelPower", po::value<int>(), "[0-1] needs {channel} (remember: the panel needs some time to boot)")
		("setPanelPowerMask", po::value<std::string>(), "8 bit mask in hex, each bit corresponds to one channel (remember: the panel needs some time to boot)")
		("setIrqEnable", po::value<int>(), "[0-1] interrupt from FPGA to ARM")
		("setPixelRatePeriod", po::value<int>(), "[0-65535] in seconds, no counter reset if 0")
		("setPacketConfigMask", po::value<std::string>(), "each bit enables one type of packets in the main fifo")
		("setPacketDrs4Sampling", po::value<int>(), "[0-1] enables data type for fifo")
		("setPacketDrs4Baseline", po::value<int>(), "[0-1] enables data type for fifo")
		("setPacketDrs4Charge", po::value<int>(), "[0-1] enables data type for fifo")
		("setPacketDrs4Timing", po::value<int>(), "[0-1] enables data type for fifo")
		("setPacketTriggerTiming", po::value<int>(), "[0-1] enables data type for fifo")
		("setPacketWhiteRabbit", po::value<int>(), "[0-1] enables data type for fifo")
		("setPacketGps", po::value<int>(), "[0-1] enables data type for fifo")
		("setPacketPixelRates", po::value<int>(), "[0-1] enables data type for fifo")
		("setSoftTriggerSingleShot", po::value<int>(), "no value")
		("setSoftTriggerGeneratorEnable", po::value<int>(), "[0,1]")
		("setSoftTriggerGeneratorPeriod", po::value<int>(), "[0-2^32] in ~8ns steps")
//			("", po::value<int>(), "")
		;

	po::variables_map vm;
	try
	{
		po::store(po::command_line_parser(argc, argv).options(desc).allow_unregistered().run(), vm);
	}
	catch (boost::program_options::invalid_command_line_syntax &e)
	{
		std::cerr << "error parsing command line: " << e.what() << std::endl;
		return EXIT_ERROR;
	}
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

	if(vm.count("setTriggerTheshold"))
	{
		if(!vm.count("channel")){std::cout << "'setTriggerTheshold' needs a 'channel'" << std::endl; return EXIT_ERROR;}
		icescint_setTriggerThreshold(vm["channel"].as<int>(), vm["setTriggerTheshold"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("setSerdesDelay"))
	{
		icescint_setSerdesDelay(vm["setSerdesDelay"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("setDrs4ReadoutMode"))
	{
		icescint_setDrs4ReadoutMode(vm["setDrs4ReadoutMode"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("setDrs4NumberOfSamplesToRead"))
	{
		icescint_setNumberOfSamplesToRead(vm["setDrs4NumberOfSamplesToRead"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("setTriggerMask"))
	{
		icescint_setTriggerMask(stringToInt(vm["setTriggerMask"].as<std::string>()));
		return EXIT_OK;
	}

	if(vm.count("setPanelPowerMask"))
	{
		icescint_setPanelPowerMask(stringToInt(vm["setPanelPowerMask"].as<std::string>()));
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

	if(vm.count("setPacketConfigMask"))
	{
		icescint_setEventFifoPacketConfig(stringToInt(vm["setPacketConfigMask"].as<std::string>()));
		return EXIT_OK;
	}

	if(vm.count("setPacketDrs4Sampling"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4SAMPLING, vm["setPacketDrs4Sampling"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}

	if(vm.count("setPacketDrs4Baseline"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4BASELINE, vm["setPacketDrs4Baseline"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}

	if(vm.count("setPacketDrs4Charge"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4CHARGE, vm["setPacketDrs4Charge"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}

	if(vm.count("setPacketDrs4Timing"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4TIMING, vm["setPacketDrs4Timing"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}

	if(vm.count("setPacketTriggerTiming"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TRIGGERTIMING, vm["setPacketTriggerTiming"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}

	if(vm.count("setPacketWhiteRabbit"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_WHITERABBIT, vm["setPacketWhiteRabbit"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}

	if(vm.count("setPacketGps"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_GPS, vm["setPacketGps"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
		return EXIT_OK;
	}

	if(vm.count("setPacketPixelRates"))
	{
		uint16_t temp = icescint_getEventFifoPacketConfig();
		temp = changeMask16(temp, MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_PIXELRATES, vm["setPacketPixelRates"].as<int>());
		icescint_setEventFifoPacketConfig(temp);
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

	return EXIT_OK;
}
