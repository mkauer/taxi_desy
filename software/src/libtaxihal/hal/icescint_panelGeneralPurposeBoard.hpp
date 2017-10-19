/*
 * icescint_panelGeneralPurposeBoard.hpp
 *
 *  Created on: Oct 05, 2017
 *      Author:
 */

#ifndef ICESCINT_HAL_ICESCINT_PANELGENERALPURPOSEBOARD_HPP_
#define ICESCINT_HAL_ICESCINT_PANELGENERALPURPOSEBOARD_HPP_

#include <hal/icescint.h>
#include <iostream>
#include <iomanip>
#include <string.h>
#include <unistd.h>
#include <sstream>

const double voltageConversionFactor = 1.812e-3;

void rs485SendString(const std::string _data, int _timeout_ms, int _verbose, int _panel)
{
	const char * data = _data.c_str();
	while(*data)
	{
		icescint_doRs485SendData(*data,_panel);
		usleep(_timeout_ms*1000);
		data++;
	}
	icescint_doRs485SendData('\r',_panel);

	if(_verbose)
	{
		std::cout << "send: '" << _data << "\\r'" << std::endl;
	}
}

void icescint_pannelSwitchToHg(int _panel, int _timeout = 100, int _verbose = 0)
{
	_panel = clipValueMax(_panel, ICESCINT_NUMBEROFCHANNELS-1);
	std::string command = "lgsel 0";
	rs485SendString(command, _timeout, _verbose, _panel);
}

void icescint_pannelSwitchToLg(int _panel, int _timeout = 100, int _verbose = 0)
{
	_panel = clipValueMax(_panel, ICESCINT_NUMBEROFCHANNELS-1);
	std::string command = "lgsel 1";
	rs485SendString(command, _timeout, _verbose, _panel);
}

void icescint_pannelSetSipmVoltage(int _panel, double _voltage, int _timeout = 100, int _verbose = 0)
{
	_panel = clipValueMax(_panel, ICESCINT_NUMBEROFCHANNELS-1);
	std::stringstream command;
	command << "pmt HBV" << std::setfill('0') << std::setw(4) << std::hex << int(_voltage/voltageConversionFactor);
	rs485SendString(command.str(), _timeout, _verbose, _panel);
}

double icescint_pannelGetSipmVoltage(int _panel, int _timeout = 100, int _verbose = 0)
{
	// not implemented... find the correct gpb-command....
//	_panel = clipValueMax(_panel, ICESCINT_NUMBEROFCHANNELS-1);
//	std::stringstream command;
//	command << "pmt HBV" << std::setfill('0') << std::setw(4) << std::hex << int(_voltage/voltageConversionFactor);
//	rs485SendString(command.str(), _timeout, _verbose, _panel);
	return 0;
}

void icescint_pannelPowerOn(int _panel, int _timeout = 100, int _verbose = 0)
{
	_panel = clipValueMax(_panel, ICESCINT_NUMBEROFCHANNELS-1);
	std::string command = "pmt HON";
	rs485SendString(command, _timeout, _verbose, _panel);
}

void icescint_pannelPowerOff(int _panel, int _timeout = 100, int _verbose = 0)
{
	_panel = clipValueMax(_panel, ICESCINT_NUMBEROFCHANNELS-1);
	std::string command = "pmt HOF";
	rs485SendString(command, _timeout, _verbose, _panel);
}

void icescint_pannelCustomCommand(int _panel, std::string _command, int _timeout = 100, int _verbose = 0)
{
	_panel = clipValueMax(_panel, ICESCINT_NUMBEROFCHANNELS-1);
	rs485SendString(_command, _timeout, _verbose, _panel);
}

#endif
