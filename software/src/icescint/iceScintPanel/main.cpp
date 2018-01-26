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

int stringHexToInt(std::string _string)
{
	int temp;
	std::stringstream interpreter;
	interpreter << std::hex << _string;
	interpreter >> temp;

	return temp;
}

int printDebug(uint16_t _panel)
{
	int length = icescint_getRs485RxFifoWords(_panel);
	std::cout << "debug length : " << length << std::endl;
	for(int i=0;i<length;i++)
	{
		if((i%10) != 0) {std::cout << ".";}
		else{std::cout << (i/10)%10;}
	}
	std::cout << std::endl;
	for(int i=0;i<length;i++)
	{
		char temp = char(icescint_getRs485Data(_panel));
		if((temp == '\r') || (temp == '\n')) {temp = '?';}
		std::cout << temp;
	}
	std::cout << std::endl;

	return 0;
}


int main(int argc, char** argv)
{
	double voltage = 0;
	int timeout = 0;
	std::string custom;
	int panel = 0;

	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
			("panel,p", po::value<int>(&panel), "chose the panel (0-7)")
			("hg", "send high gain channel to icehub")
			("lg", "send low gain channel to icehub")
			("pon", "switch high voltage for sipm on")
			("poff", "switch high voltage for sipm off")
			("sethv,s", po::value<double>(&voltage), "set the voltage in Volt e.g. [56.78], step size is ~1.812mV")
			("getrawtemperaturehex,r", "temperature value form the Hamamatsu power supply in hex")
			("getrawtemperaturedec,R", "temperature value form the Hamamatsu power supply in decimal")
//			("gettemperature,d", "temperature in °C more or less accurately corrected")
			("debug", "can help to debug the gpb messages")
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
		std::cout << "*** icescint_panel - compiled " << __DATE__ << " " << __TIME__ << " ***" << std::endl;
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
		if(vm.count("panel")){icescint_pannelSwitchToHg(panel, timeout, vm.count("verbose"));}
		else{for(int i=0;i<8;i++){icescint_pannelSwitchToHg(i, timeout, vm.count("verbose"));}}
	}
	else if(vm.count("lg"))
	{
		if(vm.count("panel")){icescint_pannelSwitchToLg(panel, timeout, vm.count("verbose"));}
		else{for(int i=0;i<8;i++){icescint_pannelSwitchToLg(i, timeout, vm.count("verbose"));}}
	}

	if(vm.count("sethv"))
	{
		if(vm.count("panel")){icescint_pannelSetSipmVoltage(panel, voltage, timeout, vm.count("verbose"));}
		else{for(int i=0;i<8;i++){icescint_pannelSetSipmVoltage(i, voltage, timeout, vm.count("verbose"));}}
	}

	if(vm.count("pon"))
	{
		if(vm.count("panel")){icescint_pannelPowerOn(panel, timeout, vm.count("verbose"));}
		else{for(int i=0;i<8;i++){icescint_pannelPowerOn(i, timeout, vm.count("verbose"));}}
	}
	else if(vm.count("poff"))
	{
		if(vm.count("panel")){icescint_pannelPowerOff(panel, timeout, vm.count("verbose"));}
		else{for(int i=0;i<8;i++){icescint_pannelPowerOff(i, timeout, vm.count("verbose"));}}
	}
	else if(vm.count("custom"))
	{
		if(vm.count("panel")){icescint_pannelCustomCommand(panel, custom, timeout, vm.count("verbose"));}
		else{for(int i=0;i<8;i++){icescint_pannelCustomCommand(i, custom, timeout, vm.count("verbose"));}}
		if(vm.count("debug")){sleep(1);printDebug(panel);return 0;}
	}

	if(vm.count("getrawtemperaturehex") || vm.count("getrawtemperaturedec") || vm.count("gettemperature"))
	{
		for(int p=0; p<8;p++)
		{
			if(vm.count("panel")){p = panel;}

			icescint_doRs485FlushRxFifo(p);
			icescint_pannelCustomCommand(p, "pmt HGT", timeout, vm.count("verbose"));
			usleep(1000*300);
			int len = icescint_getRs485RxFifoWords(p);
			if(vm.count("verbose")) {std::cout << "length: " << std::dec << len << std::endl;}

			if(vm.count("debug")){printDebug(p);return 0;}

	//		for(int i=0;i<108;i++)
			for(int i=0;i<99;i++)
			{
				icescint_getRs485Data(p);
			}

			char temp[5];
			for(int i=0;i<4;i++)
			{
				temp[i] = char(icescint_getRs485Data(p));
			}

			if(vm.count("verbose")) {std::cout << temp[0] << temp[1] << temp[2] << temp[3] << std::endl;}

			int temperature = stringHexToInt(std::string(temp));
			if(vm.count("getrawtemperaturehex")){std::cout << "0x" << std::hex << temperature << std::endl;}
			if(vm.count("getrawtemperaturedec")){std::cout << "" << std::dec << temperature << std::endl;}
	//		if(vm.count("gettemperature")){std::cout << "" << std::dec << temperature << std::endl;}
			icescint_doRs485FlushRxFifo(p);

			if(vm.count("panel")){break;}
		}
	}

	return 0;
}
