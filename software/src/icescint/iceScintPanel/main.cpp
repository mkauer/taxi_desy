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

using namespace std;
namespace po = boost::program_options;

int main(int argc, char** argv)
{
	double voltage = 0;
	int timeout = 0;
	std::string custom;
	int panel = 0;

	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
			("panel,p", po::value<int>(&panel)->default_value(0), "chose the panel (0-7)")
			("hg", "send high gain channel to icehub")
			("lg", "send low gain channel to icehub")
			("pon", "switch high voltage for sipm on")
			("poff", "switch high voltage for sipm on")
			("sethv,s", po::value<double>(&voltage), "set the voltage in Volt e.g. [56.78], step size is ~1.812mV")
			("custom,c", po::value<std::string>(&custom), "send custom command to panel (use '' if command has spaces)")
			("timeout,t", po::value<int>(&timeout)->default_value(10), "rs485 timeout in ms")
			("verbose,v", "be verbose")
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
		cout << "*** icescint_panel - compiled " << __DATE__ << " " << __TIME__ << " ***"<< endl;
		std::cout << desc << std::endl;
		return 1;
	}

	smc_driver_error_t err;
	err = smc_open(0);
	if (err != ERROR_NONE)
	{
		std::cerr << "cannot open bus driver!" << std::endl;
		return 1;
	}

	if(vm.count("hg"))
	{
		icescint_pannelSwitchToHg(panel, timeout, vm.count("verbose"));
	}
	else if(vm.count("lg"))
	{
		icescint_pannelSwitchToLg(panel, timeout, vm.count("verbose"));
	}

	if(vm.count("sethv"))
	{
		icescint_pannelSetSipmVoltage(panel, voltage, timeout, vm.count("verbose"));
	}

	if(vm.count("pon"))
	{
		icescint_pannelPowerOn(panel, timeout, vm.count("verbose"));
	}
	else if(vm.count("poff"))
	{
		icescint_pannelPowerOff(panel, timeout, vm.count("verbose"));
	}
	else if(vm.count("custom"))
	{
		icescint_pannelCustomCommand(panel, custom, timeout, vm.count("verbose"));
	}

	return 0;
}
