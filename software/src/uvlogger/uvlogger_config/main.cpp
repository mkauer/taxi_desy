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

#include <hal/uvlogger.h>
#include <hal/icescint.h>

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
		("getTriggerThreshold", "for all channels if {channel} not used")
		("setTriggerThreshold", po::value<int>(), "[0-4095] applies to all channels if {channel} not used")
		("getOffsetVoltage", "for all channels if {channel} not used")
		("setOffsetVoltage", po::value<int>(), "[0-4095] needs {channel}")
		("getHighVoltage", "for all channels if {channel} not used")
		("setHighVoltage", po::value<int>(), "[0-4095] needs {channel}")
		("setHighVoltageRampStepSize", po::value<int>()->default_value(100), "debug")
		("setHighVoltageRampStepSleep", po::value<int>()->default_value(10000), "debug in [us]")

		("setFlasherVoltageReferenceToInternal", po::value<int>(), "[0-1]")
		("getFlasherVoltage", "for all channels if {channel} not used")
		("setFlasherVoltage", po::value<int>(), "[0-4095] needs {channel}")
		("getFlasherGeneratorEnable1", "...")
		("setFlasherGeneratorEnable1", po::value<int>(), "...")
		("getFlasherGeneratorEnable2", "...")
		("setFlasherGeneratorEnable2", po::value<int>(), "...")
		("getFlasherPeriod1", "...")
		("setFlasherPeriod1", po::value<int>(), "...")
		("getFlasherPeriod2", "...")
		("setFlasherPeriod2", po::value<int>(), "...")
		("getPulseWidth1", "...")
		("setPulseWidth1", po::value<int>(), "...")
		("getPulseWidth2", "...")
		("setPulseWidth2", po::value<int>(), "...")
		("doFlasherSingleShot1", "...")
		("doFlasherSingleShot2", "...")

		("getMainBoradTemperatureRaw", "...")
		("getMainBoradTemperatureDegC", "...")
		("getFlasherTemperatureRaw", "...")
		("getFlasherTemperatureDegC", "...")

		("getPcbLedsEnable", "...")
		("setPcbLedsEnable", po::value<int>(), "...")

		("getIrqEnable", "")
		("setIrqEnable", po::value<int>(), "[0-1] interrupt from FPGA to ARM")
		("getIrqAtFifoWords", "")
		("setIrqAtFifoWords", po::value<int>(), "[1-8191] interrupt if fifo has more words")
		("getIrqAtNumberOfEvents", "")
		("setIrqAtNumberOfEvents", po::value<int>(), "[0-8192] interrupt if number of events in fifo is greater")

		("getTriggerMask", "in hex")
		("setTriggerMask", po::value<std::string>(), "8 bit mask in hex, each bit corresponds to one channel, '1' will disable and '0' will enable the channel")
		("getPixelRatePeriod", "")
		("setPixelRatePeriod", po::value<int>(), "[0-65535] in seconds, no counter reset if 0")

		("getSerdesDelay", "")
		("setSerdesDelay", po::value<int>(), "[0-1023]")
		("getDrs4ReadoutMode", "")
		("setDrs4ReadoutMode", po::value<int>(), "") // ## the spike thing...
		("getDrs4NumberOfSamplesToRead", "")
		("setDrs4NumberOfSamplesToRead", po::value<int>(), "[10-1024] more than 1024 will reread old samples")

		("getDrs4BaselineStart", "")
		("setDrs4BaselineStart", po::value<int>(), "[0-1023] needs to be less than {setDrs4NumberOfSamplesToRead}")
		("getDrs4BaselineStop", "")
		("setDrs4BaselineStop", po::value<int>(), "[0-1023] needs to be less than {setDrs4NumberOfSamplesToRead}")
		("getPacketConfigMask", "in hex")
		("setPacketConfigMask", po::value<std::string>(), "each bit enables one type of packets in the main fifo")
		("getPacketDrs4Sampling", "")
		("setPacketDrs4Sampling", po::value<int>(), "[0-1] enables data type for fifo")
		("getPacketDrs4Baseline", "")
		("setPacketDrs4Baseline", po::value<int>(), "[0-1] enables data type for fifo")
		("getPacketDrs4Charge", "")
		("setPacketDrs4Charge", po::value<int>(), "[0-1] enables data type for fifo")
		("getPacketTriggerTiming", "")
		("setPacketTriggerTiming", po::value<int>(), "[0-1] enables data type for fifo")
		("getPacketPixelRates", "")
		("setPacketPixelRates", po::value<int>(), "[0-1] enables data type for fifo")
		("doPacketMisc", "send the misc packet once, immediately")
		("setPacketMisc", po::value<int>(), "[0-1] enables data type for misc data")

		("setSoftTriggerSingleShot", po::value<int>(), "no value")

//		("setSoftTriggerGeneratorEnable", po::value<int>(), "[0,1]")
//		("setSoftTriggerGeneratorPeriod", po::value<int>(), "[0-2^32] in ~8ns steps")
		("automaticConfiguration,x", "uses a fixed configuration")
		;

	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
	po::notify(vm);

	if (vm.count("help"))
	{
		std::cout << "*** uvlogger_config - simple tool for command line based configuration | " << __DATE__ << " | " << __TIME__ << " ***" << std::endl;
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

//-----------------------------------------------------------------------------

	if(vm.count("channel"))
	{
		uint16_t temp = vm["channel"].as<int>();
		if((temp < 0) || (temp > UVLOGGER_NUMBEROFCHANNELS-1))
		{
			std::cout << "parameter 'channel' is missing" << std::endl;
			return EXIT_ERROR;
		}
		else
		{
			channel = temp;
		}
	}

	if(vm.count("setTriggerThreshold"))
	{
		if(!vm.count("channel"))
		{
			for(int i=0;i<UVLOGGER_NUMBEROFCHANNELS;i++)
			{
				uvlogger_setTriggerThreshold(i, vm["setTriggerThreshold"].as<int>());
			}
		}
		else
		{
			uvlogger_setTriggerThreshold(vm["channel"].as<int>(), vm["setTriggerThreshold"].as<int>());
		}
		return EXIT_OK;
	}
	if(vm.count("getTriggerThreshold"))
	{
		if(!vm.count("channel"))
		{
			for(int i=0;i<UVLOGGER_NUMBEROFCHANNELS;i++)
			{
				std::cout << "ch." << i << ": " << int(uvlogger_getTriggerThreshold(i)) << std::endl;
			}
		}
		else
		{
			std::cout << int(uvlogger_getTriggerThreshold(vm["channel"].as<int>())) << std::endl;
		}
		return EXIT_OK;
	}

	if(vm.count("setOffsetVoltage"))
	{
		uvlogger_setOffsetVoltage(vm["channel"].as<int>(), vm["setTriggerThreshold"].as<int>());

		return EXIT_OK;
	}
	if(vm.count("getOffsetVoltage"))
	{
		if(!vm.count("channel"))
		{
			for(int i=0;i<UVLOGGER_NUMBEROFCHANNELS;i++)
			{
				std::cout << "ch." << i << ": " << int(uvlogger_getOffsetVoltage(i)) << std::endl;
			}
		}
		else
		{
			std::cout << int(uvlogger_getOffsetVoltage(vm["channel"].as<int>())) << std::endl;
		}
		return EXIT_OK;
	}

	if(vm.count("setHighVoltage"))
	{
		if(vm.count("channel"))
		{
			uvlogger_setHighVoltageRamp(vm["channel"].as<int>(), vm["setHighVoltage"].as<int>(), vm["setHighVoltageRampStepSize"].as<int>(), vm["setHighVoltageRampStepSleep"].as<int>());
			return EXIT_OK;
		}
		else
		{
			std::cout << "parameter 'channel' is missing" << std::endl;
			return EXIT_ERROR;
		}
	}
	if(vm.count("getHighVoltage"))
	{
		if(!vm.count("channel"))
		{
			for(int i=0;i<UVLOGGER_NUMBEROFCHANNELS;i++)
			{
				std::cout << "ch." << i << ": " << int(uvlogger_getHighVoltage(i)) << std::endl;
			}
		}
		else
		{
			std::cout << int(uvlogger_getHighVoltage(vm["channel"].as<int>())) << std::endl;
		}
		return EXIT_OK;
	}

	if(vm.count("setFlasherVoltageReferenceToInternal"))
	{
		uvlogger_setFlasherVoltageReferenceToInternal(vm["setFlasherVoltageReferenceToInternal"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("setFlasherVoltage"))
	{
		if(vm.count("channel"))
		{
			uvlogger_setFlasherVoltage(vm["channel"].as<int>(), vm["setFlasherVoltage"].as<int>());
			return EXIT_OK;
		}
		else
		{
			std::cout << "parameter 'channel' is missing" << std::endl;
			return EXIT_ERROR;
		}
	}
	if(vm.count("getFlasherVoltage"))
	{
		if(!vm.count("channel"))
		{
			for(int i=0;i<UVLOGGER_NUMBEROFCHANNELS;i++)
			{
				std::cout << "ch." << i << ": " << int(uvlogger_getFlasherVoltage(i)) << std::endl;
			}
		}
		else
		{
			std::cout << int(uvlogger_getFlasherVoltage(vm["channel"].as<int>())) << std::endl;
		}
		return EXIT_OK;
	}

	if(vm.count("setFlasherGeneratorEnable1"))
	{
		uvlogger_setFlasherGeneratorEnable1(vm["setFlasherGeneratorEnable1"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getFlasherGeneratorEnable1"))
	{
		std::cout << int(uvlogger_getFlasherGeneratorEnable1()) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setFlasherGeneratorEnable2"))
	{
		uvlogger_setFlasherGeneratorEnable2(vm["setFlasherGeneratorEnable2"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getFlasherGeneratorEnable2"))
	{
		std::cout << int(uvlogger_getFlasherGeneratorEnable2()) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setFlasherPeriod1"))
	{
		uvlogger_setFlasherGeneratorPeriod(0, vm["setFlasherPeriod1"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getFlasherPeriod1"))
	{
		std::cout << int(uvlogger_getFlasherGeneratorPeriod(0)) << std::endl;
		return EXIT_OK;
	}
	if(vm.count("setFlasherPeriod2"))
	{
		uvlogger_setFlasherGeneratorPeriod(1, vm["setFlasherPeriod2"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getFlasherPeriod2"))
	{
		std::cout << int(uvlogger_getFlasherGeneratorPeriod(1)) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPulseWidth1"))
	{
		uvlogger_setFlasherPulseWidth(0, vm["setPulseWidth1"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getPulseWidth1"))
	{
		std::cout << int(uvlogger_getFlasherPulseWidth(0)) << std::endl;
		return EXIT_OK;
	}
	if(vm.count("setPulseWidth2"))
	{
		uvlogger_setFlasherPulseWidth(1, vm["setPulseWidth2"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getPulseWidth2"))
	{
		std::cout << int(uvlogger_getFlasherPulseWidth(1)) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("doFlasherSingleShot1"))
	{
		uvlogger_doFlasherSingleShot(0);
		return EXIT_OK;
	}
	if(vm.count("doFlasherSingleShot2"))
	{
		uvlogger_doFlasherSingleShot(1);
		return EXIT_OK;
	}

	if(vm.count("getMainBoradTemperatureDegC"))
	{
		std::cout << std::dec << uvlogger_getTemperatureMainBoardTmp10x_degC();
		std::cout << "^C";
		std::cout << std::endl;
		return EXIT_OK;
	}
	if(vm.count("getMainBoradTemperatureRaw"))
	{
		std::cout << std::dec << int(uvlogger_getTemperatureMainBoardTmp10x());
		std::cout << std::endl;
		return EXIT_OK;
	}

	if(vm.count("getFlasherTemperatureDegC"))
	{
		std::cout << std::dec << uvlogger_getTemperatureFlasherBoardTmp10x_degC();
		std::cout << "^C";
		std::cout << std::endl;
		return EXIT_OK;
	}
	if(vm.count("getFlasherTemperatureRaw"))
	{
		std::cout << std::dec << int(uvlogger_getTemperatureFlasherBoardTmp10x());
		std::cout << std::endl;
		return EXIT_OK;
	}

	if(vm.count("setPcbLedsEnable"))
	{
		uvlogger_setHouskeepingPcbLedsEnable(vm["setPcbLedsEnable"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("getPcbLedsEnable"))
	{
		std::cout << int(uvlogger_getHouskeepingPcbLedsEnable()) << std::endl;
		return EXIT_OK;
	}

	if(vm.count("triggermask"))
	{
		icescint_setTriggerMask(stringToInt(vm["triggermask"].as<std::string>()));
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
		for(int i=0;i<8;i++) {uvlogger_setTriggerThreshold(i, 0xc00);}
		icescint_setSerdesDelay(110);
		drs4_setDrs4ReadoutMode(6);
		drs4_setNumberOfSamplesToRead(64);
		icescint_setTriggerMask(0x00);
		icescint_setIrqAtFifoWords(4096);
		icescint_setIrqAtEventCount(100);
		icescint_setIrqEnable(1);
		icescint_setPixelTriggerCounterPeriod(1);

		icescint_setEventFifoPacketConfig( 0x0
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4SAMPLING
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4BASELINE
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4CHARGE
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4TIMING
			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TRIGGERTIMING
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TEST_DATA1
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_TEST_DATA2
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_MISC
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_WHITERABBIT
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_GPS
			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_PIXELRATES
//			| MASK_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DEBUG
			);

		icescint_setBaselineStart(0);
		icescint_setBaselineStop(10);
		icescint_setSoftTriggerGeneratorPeriod(0x8000000);
		icescint_setSoftTriggerGeneratorEnable(0);

		uvlogger_setFlasherVoltageReferenceToInternal(1);

		return EXIT_OK;
	}

	return EXIT_OK;
}
