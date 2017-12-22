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

#include <bitset>
#include <boost/algorithm/string/replace.hpp>

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
		std::cout << "*** iceScintIrigDebugger | " << __DATE__ << " | " << __TIME__ << " ***" << std::endl;
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

	uint16_t data[10] = {1,2,3,4,5,6,7,8,9,0};

	while(1)
	{
		icescint_getIrig(data);
//		std::cout << std::hex << int(data[0]) << " " << int(data[1])  << " "<< int(data[2])  << " "<< int(data[3])  << " "<< int(data[4]) << " " << int(data[5]) << std::dec <<std::endl;
//		std::cout << "a: ";
//		for(int i=0;i<6;i++)
//		{
//			std::string temp = std::bitset<16>(*(data+i)).to_string();
//			boost::replace_all(temp, "0", ".");
//			std::cout << temp;
//			std::cout << "|";
//		}
//		std::cout << std::endl;

//		std::cout << "b: ";
		for(int i=5;i>=0;i--)
		{
			for(int j=15;j>=0;j--)
			{
				if((*(data+i) & (1<<j)) == 0) {std::cout << ".";}
				else {std::cout << "1";}
			}
			std::cout << "|";
		}
		std::cout << std::endl;

		sleep(1);
	}



	return EXIT_OK;
}
