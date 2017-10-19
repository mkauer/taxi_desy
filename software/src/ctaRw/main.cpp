
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

uint16_t transferSpi(uint16_t _slot, uint16_t _register, int _rw, uint16_t _value, int _spiTimeout)
{
	if(validateSettings(_slot, 1, 1) == EXIT_OK)
	{
		waitForSpi(_spiTimeout);

		uint16_t config = (_register & 0xff) | ((_slot << 8)&0x1f00);

		if(_rw) {config |= 0x8000;}

		IOWR_16DIRECT(BASE_CTA_L2CB, ADDR_CTA_L2CB_SPTX, _value);
		IOWR_16DIRECT(BASE_CTA_L2CB, ADDR_CTA_L2CB_SPAD, config);

		waitForSpi(_spiTimeout);

		return IORD_16DIRECT(BASE_CTA_L2CB, ADDR_CTA_L2CB_SPRX);
	}
	else
	{
		cout << "no spi transfer to slot " << _slot << " started..." << endl;
		return 0;
	}
}

int main(int argc, char** argv)
{
	uint16_t temp = 0;

	int iterate = 1;
	int times = 1;
	int slot = 1;
	int spiTimeout = 0;

	smc_driver_error_t err;
	err = smc_open(0);
	if (err != ERROR_NONE)
	{
		std::cerr << "cannot open bus driver!" << std::endl;
		return 1;
	}

	po::options_description desc("Allowed options");
	desc.add_options()
		("help,h", "show help message")
		("slot,s", po::value<std::string>(), "slot [1-9,13-21] in crate; left is 1, right is 21")
		("read,r", po::value<std::string>(), "read from address [hex]")
		("write,w", po::value<std::string>(), "write to address [hex]")
		("value,v", po::value<std::string>(), "value to write [hex]")
		("compare,c", "read back the written value and compare")
		//("iterate,i", po::value<int>(&iterate)->default_value(1), "increments i times the address by 2 and reads/writes the selected value")
		//("times,t", po::value<int>(&times)->default_value(1), "number of read cycles per address")
		("decimal,d", "all values for read and write are [dec]")
		("spitimeout,p", po::value<int>(&spiTimeout)->default_value(1000), "debug in [us]")
	;

	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
	po::notify(vm);

	if (vm.count("help") || !(vm.count("read") || vm.count("write")))
	{
		cout << "*** cta_rw - simple read/write tool for the digital trigger crate " << __DATE__ << " " << __TIME__ << " ***"<< endl;
		cout << desc << "\n";
	    return EXIT_ERROR;
	}

	if (vm.count("slot"))
	{
		std::stringstream interpreter;
		interpreter << std::dec << vm["slot"].as<std::string>();
		interpreter >> slot;
	}

	if (vm.count("read"))
	{
		int addr  = 0;
		std::stringstream interpreter;
		interpreter << std::hex << vm["read"].as<std::string>();
		interpreter >> addr;

		for(int i=0; i<iterate;i++)
		{
			for(int j=0; j<times;j++)
			{
				uint16_t value = transferSpi(slot, addr, 0, 0, spiTimeout);
				if(vm.count("decimal"))
				{
					std::cout << "read register [0x" << std::hex << addr << "] from slot " << slot << ": " << std::dec << "" << int(value) << std::dec << std::endl;
				}
				else
				{
					std::cout << "read from [0x" << std::hex << addr << "] from slot " << slot << ": " << "0x" << int(value) << std::dec << std::endl;
				}
			}
			addr += 2;
		}
	}

	if(vm.count("write"))
	{
		if(vm.count("value"))
		{
			int addr  = 0;
			std::stringstream interpreter;
			interpreter << std::hex << vm["write"].as<std::string>();
			interpreter >> addr;

			int value = 0;
			std::stringstream interpreter2;
			if(vm.count("decimal")) {interpreter2 << std::dec << vm["value"].as<std::string>();}
			else {interpreter2 << std::hex << vm["value"].as<std::string>();}
			interpreter2 >> value;

			for(int i=0; i<iterate;i++)
			{
				for(int j=0; j<times;j++)
				{
//					IOWR_16DIRECT(addr, 0, value);
					transferSpi(slot, addr, 1, value, spiTimeout);
					if(vm.count("decimal"))
					{
						std::cout << "write to register [0x" << std::hex << addr << "] on slot " << slot << ": " << std::dec << "" << value << std::dec;
					}
					else
					{
						std::cout << "write to register [0x" << std::hex << addr << "] on slot " << slot << ": " << "0x" << value << std::dec;
					}

					if(vm.count("compare"))
					{
//						int valueRead = IORD_16DIRECT(addr, 0);
						int valueRead = transferSpi(slot, addr, 0, 0, spiTimeout);
						if(valueRead == value)
						{
							std::cout << " ok" << std::endl;
						}
						else
						{
							std::cout << " failed: 0x" << std::hex << value << " != " << "0x" << valueRead << std::dec << std::endl;
						}
					}
					else
					{
						 std::cout << std::endl;
					}
				}
				addr += 2;
			}
		}
		else
		{
			std::cout << "no --value selected" << std::endl;
		}
	}

	return EXIT_OK;
}
