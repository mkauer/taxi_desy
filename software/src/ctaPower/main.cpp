
#include <iostream>
#include <string>

#include "hal/smc.h"
#include "hal/bits.h"

#include <boost/program_options.hpp>


using namespace std;
namespace po = boost::program_options;

#define EXIT_OK 0
#define EXIT_ERROR -1

#define BASE_CTA_L2CB			0x00
#define ADDR_CTA_L2CB_CTRL		0x00
#define ADDR_CTA_L2CB_STAT		0x02
#define BIT_CTA_L2CB_STAT_SPIBUSY	1
#define ADDR_CTA_L2CB_SPAD		0x04
#define ADDR_CTA_L2CB_SPTX		0x06
#define ADDR_CTA_L2CB_SPRX		0x08
#define ADDR_CTA_L2CB_TSTMP0	0x0a
#define ADDR_CTA_L2CB_TSTMP1	0x0c
#define ADDR_CTA_L2CB_TSTMP2	0x0e
#define ADDR_CTA_L2CB_TEST		0x10

#define ADDR_CTA_CTCB_PONF		0x00

void waitForSpi(int _sleepTime_us)
{
	int timeout = 0;
//	--int sleepTime_us = 10000;

	usleep(_sleepTime_us);

	while(testBitVal16(IORD_16DIRECT(BASE_CTA_L2CB, ADDR_CTA_L2CB_STAT), BIT_CTA_L2CB_STAT_SPIBUSY))
	{
		// busy
		usleep(_sleepTime_us);
		timeout++;
		if((timeout > 100) && (timeout%100 == 1))
		{
			cout << "error: spi bus is busy" << endl;
//			cout << "error: spi bus is busy, timeout after " << (sleepTime_us*timeout)/1000  << "ms" << endl;
//			return EXIT_ERROR;
		}
	}
}

uint16_t transferSpi(uint16_t _slot, uint16_t _register, int _rw, uint16_t _value, int _spiTimeout)
{
	waitForSpi(_spiTimeout);

	uint16_t config = (_register & 0xff) | ((_slot << 8)&0x1f00);

	if(_rw) {config |= 0x8000;}

	IOWR_16DIRECT(BASE_CTA_L2CB, ADDR_CTA_L2CB_SPTX, _value);
	IOWR_16DIRECT(BASE_CTA_L2CB, ADDR_CTA_L2CB_SPAD, config);

	waitForSpi(_spiTimeout);

	return IORD_16DIRECT(BASE_CTA_L2CB, ADDR_CTA_L2CB_SPRX);
}

int validateSettings(int _slot, int _channel, int _action)
{
	if((_slot > 21) || (_slot < 1) || (_slot == 10) || (_slot == 11) || (_slot ==12))
	{
		cout << "error: 'slot' outside of valid range: [1-9,13-21]" << endl;
		return EXIT_ERROR;
	}
	if((_channel > 15) || (_channel < 1))
	{
		cout << "error: 'channel' outside of valid range: [1-15]" << endl;
		return EXIT_ERROR;
	}
	if((_action > 1) || (_action < 0))
	{
		cout << "error: 'action' outside of valid range: [0-1]" << endl;
		return EXIT_ERROR;
	}

	return EXIT_OK;
}

int changeSettings(int _slot, int _channel, int _action, int _spiTimeout)
{
	uint16_t valid = validateSettings(_slot,_channel,_action);
	if(valid != EXIT_OK) {return valid;}

	uint16_t powerStatus = transferSpi(_slot, ADDR_CTA_CTCB_PONF, 0, 0, _spiTimeout);
//	cout << "debug: register from spi: 0x" << std::hex << int(powerStatus) << endl;

	powerStatus = changeBitVal16(powerStatus, _channel, _action);
//	cout << "debug: changed value to: 0x" << std::hex << int(powerStatus) << endl;

	powerStatus = transferSpi(_slot, ADDR_CTA_CTCB_PONF, 1, powerStatus, _spiTimeout);
//	cout << "debug: register from spi: 0x" << std::hex << int(powerStatus) << endl;

	return EXIT_OK;
}

int changeSettingsMask(int _slot, int _channelMask, int _spiTimeout)
{
	uint16_t valid = validateSettings(_slot,1,0);
	if(valid != EXIT_OK) {return valid;}

	uint16_t powerStatus = transferSpi(_slot, ADDR_CTA_CTCB_PONF, 0, 0, _spiTimeout);

//	cout << "debug: register from spi: 0x" << std::hex << int(powerStatus) << endl;

	transferSpi(_slot, ADDR_CTA_CTCB_PONF, 1, _channelMask, _spiTimeout);

	return EXIT_OK;
}

int readSettings(int _slot, int _channel, uint16_t* _status, int _spiTimeout)
{
	uint16_t valid = validateSettings(_slot,_channel,0);
	if(valid != EXIT_OK) {return valid;}

	*_status = transferSpi(_slot, ADDR_CTA_CTCB_PONF, 0, 0, _spiTimeout);

	return EXIT_OK;
}

int main(int argc, char** argv)
{
	uint16_t temp = 0;

	smc_driver_error_t err;
	err = smc_open(0);
	if (err != ERROR_NONE)
	{
		std::cerr << "cannot open bus driver!" << std::endl;
		return 1;
	}

	int action = 0;
	int channel = 0;
	int slot = 0;
	int mask = 0;
	int spiTimeout = 0;

	po::options_description desc("Allowed options");
	desc.add_options()
	    ("help,h", "show help message")
	    ("slot,s", po::value<std::string>(), "slot [1-9,13-21] in crate; left is 1, right is 21")
	    ("channel,c", po::value<std::string>(), "channel [1-15] at slot; top channel is 1, bottom channel is 15")
		("action,a", po::value<std::string>(), "[0-1] 0=off, 1=on")
		("status,t", po::value<std::string>(), "read back the actual status")
		("read,r", po::value<std::string>(), "debug")
		("spitimeout,p", po::value<int>(&spiTimeout)->default_value(1000), "debug in [us]")
		("mask,m", po::value<std::string>(), "provide the bit value (in hex) for a whole slot")
		("all", "use with or without slot and/or channel")
		("on", "same as --action 1")
		("off", "same as --action 0")
	;

	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
	po::notify(vm);

	if (vm.count("help"))
	{
		cout << "*** cta_power | " << __DATE__ << " " << __TIME__ << " ***"<< endl;
		cout << desc << "\n";
	    return EXIT_ERROR;
	}

	if (vm.count("slot"))
	{
		std::stringstream interpreter;
		interpreter << std::dec << vm["slot"].as<std::string>();
		interpreter >> slot;
	}

	if(vm.count("channel"))
	{
		std::stringstream interpreter;
		interpreter << std::dec << vm["channel"].as<std::string>();
		interpreter >> channel;
	}

	if(vm.count("mask"))
	{
		std::stringstream interpreter;
		interpreter << std::hex << vm["channel"].as<std::string>();
		interpreter >> mask;
		mask = mask & 0xffff;
	}

	if(vm.count("action") || vm.count("on") || vm.count("off"))
	{
		if(vm.count("action"))
		{
			std::stringstream interpreter;
			interpreter << std::dec << vm["action"].as<std::string>();
			interpreter >> action;
			if(action){action = 1;}

			if( vm.count("on") || vm.count("off"))
			{
				std::cout << "use --mask or --on/--off or --action" << std::endl;
				return EXIT_OK;
			}
		}
		if(vm.count("on")) {action = 1;}
		if(vm.count("off")) {action = 0;}

		if(vm.count("mask"))
		{
			std::cout << "use [--mask | --on | --off | --action]" << std::endl;
			return EXIT_OK;
		}
		if( vm.count("on") && vm.count("off"))
		{
			std::cout << "use [--mask | --on | --off | --action]" << std::endl;
			return EXIT_OK;
		}

	}

	if (vm.count("slot") && vm.count("channel") && (vm.count("action") || vm.count("on") || vm.count("off")))
	{
		uint16_t ret = changeSettings(slot,channel,action,spiTimeout);
		uint16_t status = 0;
		if(vm.count("status"))
		{
			readSettings(slot,channel,&status,spiTimeout);
			cout << "readback after write: 0x" << std::hex << int(status) << endl;
		}
		return ret;
	}
	else if(vm.count("status") && vm.count("slot") && vm.count("channel"))
	{
		uint16_t status = 0;
		readSettings(slot,channel,&status,spiTimeout);
//		cout << "readback: 0x" << std::hex << int(status) << endl;
	}
	else if(vm.count("all") && vm.count("slot") && (vm.count("action") || vm.count("on") || vm.count("off")))
	{
		if(vm.count("mask")){}
		if(vm.count("on") || vm.count("action")){mask = 0xfffe;}
		if(vm.count("mask")){mask = 0;}


		if(action == 1){changeSettingsMask(slot,mask,spiTimeout);}
		else if(action == 0){changeSettingsMask(slot,mask,spiTimeout);}
	}
	else if(vm.count("all") && (vm.count("action") || vm.count("on") || vm.count("off")))
	{
		if(action == 1)
		{
			for(int i=1; i<=9;i++) {changeSettingsMask(i,0xfffe,spiTimeout);}
			for(int i=13; i<=21;i++) {changeSettingsMask(i,0xfffe,spiTimeout);}
		}
		else if(action == 0)
		{
			for(int i=1; i<=9;i++) {changeSettingsMask(i,0x0,spiTimeout);}
			for(int i=13; i<=21;i++) {changeSettingsMask(i,0x0,spiTimeout);}
		}
	}
	else if(!vm.count("slot"))
	{
		std::cout << "no value selected for slot" << std::endl;
	}
	else if(!vm.count("channel"))
	{
		std::cout << "no value selected for channel" << std::endl;
	}
	else if(!vm.count("action"))
	{
		std::cout << "no value selected for action" << std::endl;
	}

	if(vm.count("read"))
	{
		int r=0;

		if(vm.count("read"))
		{
			std::stringstream interpreter;
			interpreter << std::hex << vm["read"].as<std::string>();
			interpreter >> r;
		}

		std::cout << "debug r:" << r << std::endl;
		int x = IORD_16DIRECT(r,0);
		std::cout << "x: " << x << "\ndebug end" << std::endl;
	}

	return EXIT_OK;
}
