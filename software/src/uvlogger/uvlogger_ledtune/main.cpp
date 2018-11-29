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
		("setHighVoltageRampStepSize", po::value<int>()->default_value(100), "debug")
		("setHighVoltageRampStepSleep", po::value<int>()->default_value(10000), "debug in [us]")

		("suv", po::value<int>(), "setAvalancheVoltage (UV-LED) [0-4095]")
		("guv", "getAvalancheVoltage ...")
		("iuv", po::value<int>(), "incAvalancheVoltage [0-x]")
		("duv", po::value<int>(), "decAvalancheVoltage [0-x]")

		("svv", po::value<int>(), "setVaricapVoltage (UV-LED) [0-4095]")
		("gvv", "getVaricapVoltage ...")
		("ivv", po::value<int>(), "incVaricapVoltage [0-x]")
		("dvv", po::value<int>(), "decVaricapVoltage [0-x]")

		("sbv", po::value<int>(), "setBlueLedVoltage [0-4095]")
		("gbv", "getBlueLedVoltage ...")
		("ibv", po::value<int>(), "incBlueLedVoltage [0-x]")
		("dbv", po::value<int>(), "decBlueLedVoltage [0-x]")

		("sav", po::value<int>(), "setAttenuatorVoltage (blue LED) [0-4095]")
		("gav", "getAttenuatorVoltage ...")
		("iav", po::value<int>(), "incAttenuatorVoltage [0-x]")
		("dav", po::value<int>(), "decAttenuatorVoltage [0-x]")


		("g1", po::value<int>(), "enable flasher 1 (blue LED) [0,1]")
		("g2", po::value<int>(), "enable flasher 2 (UV-LED) [0,1]")
		("p1", po::value<int>(), "set flasher1 period (8.4ns ticks)")
		("p2", po::value<int>(), "set flasher2 period (8.4ns ticks)")
		("f1", po::value<float>(), "set flasher1 frequency (Hz)")
		("f2", po::value<float>(), "set flasher2 frequency (Hz)")
		("w1", po::value<int>(), "flasher 1 LED pulse width [0-15]")
		("w2", po::value<int>(), "flasher 2 LED pulse width [0-15]")
		("ss1", "send single flasher pulse (blue)")
		("ss2", "send single flasher pulse (UV)")

		//("automaticConfiguration,x", "uses a fixed configuration")
		("enableInternalReference,z", "debug...")
		;

	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
	po::notify(vm);

	if (vm.count("help"))
	{
		std::cout << "*** uvlogger_ledtune - simple tool for command line based flasher led configuration | " << __DATE__ << " | " << __TIME__ << " ***" << std::endl;
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
	const int uvChannel = 6;
	const int blueChannel = 0;
	const int variCapChannel = 1;
	const int attenuatorChannel = 2;

	if(vm.count("suv"))
	{
		uvlogger_setHighVoltageRamp(uvChannel, vm["suv"].as<int>(), vm["setHighVoltageRampStepSize"].as<int>(), vm["setHighVoltageRampStepSleep"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("guv"))
	{
		std::cout << int(uvlogger_getHighVoltage(uvChannel)) << std::endl;
		return EXIT_OK;
	}
	if(vm.count("iuv"))
	{
		uint16_t value = uvlogger_getHighVoltage(uvChannel);
		value = value + vm["iuv"].as<int>();
		uvlogger_setHighVoltageRamp(uvChannel, value, vm["setHighVoltageRampStepSize"].as<int>(), vm["setHighVoltageRampStepSleep"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("duv"))
	{
		uint16_t value = uvlogger_getHighVoltage(uvChannel);
		value = value - vm["duv"].as<int>();
		uvlogger_setHighVoltageRamp(uvChannel, value, vm["setHighVoltageRampStepSize"].as<int>(), vm["setHighVoltageRampStepSleep"].as<int>());
		return EXIT_OK;
	}

	if(vm.count("sbv"))
	{
		uvlogger_setFlasherVoltage(blueChannel, vm["sbv"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("gbv"))
	{
		std::cout << int(uvlogger_getFlasherVoltage(blueChannel)) << std::endl;
		return EXIT_OK;
	}
	if(vm.count("ibv"))
	{
		uint16_t value = uvlogger_getFlasherVoltage(blueChannel);
		value = value + vm["ibv"].as<int>();
		uvlogger_setFlasherVoltage(blueChannel, value);
		return EXIT_OK;
	}
	if(vm.count("dbv"))
	{
		uint16_t value = uvlogger_getFlasherVoltage(blueChannel);
		value = value - vm["dbv"].as<int>();
		uvlogger_setFlasherVoltage(blueChannel, value);
		return EXIT_OK;
	}

	if(vm.count("svv"))
	{
		uvlogger_setFlasherVoltage(variCapChannel, vm["svv"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("gvv"))
	{
		std::cout << int(uvlogger_getFlasherVoltage(variCapChannel)) << std::endl;
		return EXIT_OK;
	}
	if(vm.count("ivv"))
	{
		uint16_t value = uvlogger_getFlasherVoltage(variCapChannel);
		value = value + vm["ivv"].as<int>();
		uvlogger_setFlasherVoltage(variCapChannel, value);
		return EXIT_OK;
	}
	if(vm.count("dvv"))
	{
		uint16_t value = uvlogger_getFlasherVoltage(variCapChannel);
		value = value - vm["dvv"].as<int>();
		uvlogger_setFlasherVoltage(variCapChannel, value);
		return EXIT_OK;
	}

	if(vm.count("sav"))
	{
		uvlogger_setFlasherVoltage(attenuatorChannel, vm["sav"].as<int>());
		return EXIT_OK;
	}
	if(vm.count("gav"))
	{
		std::cout << int(uvlogger_getFlasherVoltage(attenuatorChannel)) << std::endl;
		return EXIT_OK;
	}
	if(vm.count("iav"))
	{
		uint16_t value = uvlogger_getFlasherVoltage(attenuatorChannel);
		value = value + vm["iav"].as<int>();
		uvlogger_setFlasherVoltage(attenuatorChannel, value);
		return EXIT_OK;
	}
	if(vm.count("dav"))
	{
		uint16_t value = uvlogger_getFlasherVoltage(attenuatorChannel);
		value = value - vm["dav"].as<int>();
		uvlogger_setFlasherVoltage(attenuatorChannel, value);
		return EXIT_OK;
	}

	if(vm.count("g1"))
	{
		uvlogger_setFlasherGeneratorEnable1(vm["g1"].as<int>());
		return EXIT_OK;
	}
//	if(vm.count("getFlasherGeneratorEnable1"))
//	{
//		std::cout << int(uvlogger_getFlasherGeneratorEnable1()) << std::endl;
//		return EXIT_OK;
//	}

	if(vm.count("g2"))
	{
		uvlogger_setFlasherGeneratorEnable2(vm["g2"].as<int>());
		return EXIT_OK;
	}
//	if(vm.count("getFlasherGeneratorEnable2"))
//	{
//		std::cout << int(uvlogger_getFlasherGeneratorEnable2()) << std::endl;
//		return EXIT_OK;
//	}

	if(vm.count("p1"))
	{
		uvlogger_setFlasherGeneratorPeriod(0, vm["p1"].as<int>());
		return EXIT_OK;
	}
//	if(vm.count("getFlasherPeriod1"))
//	{
//		std::cout << int(uvlogger_getFlasherGeneratorPeriod(0)) << std::endl;
//		return EXIT_OK;
//	}
	if(vm.count("p2"))
	{
		uvlogger_setFlasherGeneratorPeriod(1, vm["p2"].as<int>());
		return EXIT_OK;
	}
//	if(vm.count("getFlasherPeriod2"))
//	{
//		std::cout << int(uvlogger_getFlasherGeneratorPeriod(1)) << std::endl;
//		return EXIT_OK;
//	}
	if(vm.count("f1"))
	{
		uvlogger_setFlasherGeneratorFrequency(0, vm["f1"].as<float>());
		return EXIT_OK;
	}
	if(vm.count("f2"))
	{
		uvlogger_setFlasherGeneratorFrequency(1, vm["f2"].as<float>());
		return EXIT_OK;
	}

	if(vm.count("w1"))
	{
		uvlogger_setFlasherPulseWidth(0, vm["w1"].as<int>());
		return EXIT_OK;
	}
//	if(vm.count("getPulseWidth1"))
//	{
//		std::cout << int(uvlogger_getFlasherPulseWidth(0)) << std::endl;
//		return EXIT_OK;
//	}
	if(vm.count("w2"))
	{
		uvlogger_setFlasherPulseWidth(1, vm["w2"].as<int>());
		return EXIT_OK;
	}
//	if(vm.count("getPulseWidth2"))
//	{
//		std::cout << int(uvlogger_getFlasherPulseWidth(1)) << std::endl;
//		return EXIT_OK;
//	}

	if(vm.count("ss1"))
	{
		uvlogger_doFlasherSingleShot(0);
		return EXIT_OK;
	}
	if(vm.count("ss2"))
	{
		uvlogger_doFlasherSingleShot(1);
		return EXIT_OK;
	}

	if(vm.count("enableInternalReference"))
	{
		uvlogger_setFlasherVoltageReferenceToInternal(1);

		return EXIT_OK;
	}

	return EXIT_OK;
}
