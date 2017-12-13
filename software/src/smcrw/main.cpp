#include <iostream>
#include <string>

#include <boost/program_options.hpp>

#include "hal/smc.h"

namespace po = boost::program_options;

#define EXIT_OK 0
#define EXIT_ERROR -1

int main(int argc, char** argv)
{
	uint16_t temp = 0;

	smc_open(NULL);
	int iterate;
	int times;

	po::options_description desc("Allowed options");
	desc.add_options()
		("help,h", "show help message")
		("read,r", po::value<std::string>(), "read from address [hex]")
		("write,w", po::value<std::string>(), "write to address [hex]")
		("value,v", po::value<std::string>(), "value to write [hex]")
		("compare,c", "read back the written value and compare")
		("iterate,i", po::value<int>(&iterate)->default_value(1), "increments i times the address by 2 and reads/writes the selected value")
		("times,t", po::value<int>(&times)->default_value(1), "number of read cycles per address")
		("decimal,d", "all values for read and write are [dec]")
		("ascii,a", "all values for read and write are ascii (first char only if ore are given)")
	;

	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
	po::notify(vm);

	if (vm.count("help") || !(vm.count("read") || vm.count("write")))
	{
		std::cout << "*** smcrw - simple read/write tool for the smc interface" << __DATE__ << " " << __TIME__ << " ***" << std::endl;
		std::cout << desc << std::endl;
	    return EXIT_ERROR;
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
				uint16_t value = IORD_16DIRECT(addr, 0);
				if(vm.count("decimal"))
				{
					std::cout << "read from [0x" << std::hex << addr << "]: " << std::dec << "" << int(value) << std::dec << std::endl;
				}
				else if(vm.count("ascii"))
				{
					std::cout << "read from [0x" << std::hex << addr << "]: " << std::dec << "'" << char(value) << "'" << std::dec << std::endl;
				}
				else
				{
					std::cout << "read from [0x" << std::hex << addr << "]: " << "0x" << int(value) << std::dec << std::endl;
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
			//interpreter2 << std::hex << vm["value"].as<std::string>();
			if(vm.count("decimal")) {interpreter2 << std::dec << vm["value"].as<std::string>(); interpreter2 >> value;}
			else if(vm.count("ascii")) {value = vm["value"].as<std::string>().at(0);}
			else {interpreter2 << std::hex << vm["value"].as<std::string>(); interpreter2 >> value;}
//			interpreter2 >> value;

			for(int i=0; i<iterate;i++)
			{
				for(int j=0; j<times;j++)
				{
					IOWR_16DIRECT(addr, 0, value);
					if(vm.count("decimal"))
					{
						std::cout << "write to [0x" << std::hex << addr << "]: " << std::dec << "" << value << std::dec;
					}
					else
					{
						std::cout << "write to [0x" << std::hex << addr << "]: " << "0x" << value << std::dec;
					}

					if(vm.count("compare"))
					{
						int valueRead = IORD_16DIRECT(addr, 0);
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
