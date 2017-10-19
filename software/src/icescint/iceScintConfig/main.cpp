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

using namespace std;
namespace po = boost::program_options;


//---------------------------------------------

int main(int argc, char** argv)
{
	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
			("triggermask,m", "8 bit in hex")
			("singlesofttrigger,s", "[1]")
			("softtriggergeneratorenable,g", "[0,1]")
			("softtriggergeneratorperiod,p", "in ~8ns steps")

//			("verbose,v", "be verbose")
//			("server", po::value<std::string>(&server)->default_value("192.168.1.1"), "server data is send to")
//			("port", po::value<int>(&port)->default_value(10011), "server port data is send to")
//			("newfiletimeout,f", po::value<int>(&newFileTimeout)->default_value(-1), "new file will be created after [sec]")
//			("newfiletime,m", po::value<int>(&newFileTime)->default_value(-1), "new file will be created after [sec] from UTC midnight")
//			("newfilePath,p", po::value<std::string>(&newFilePath)->default_value("/tmp/"), "new file will be created here")
//			("writefile,w", "write to file if true")
//			("createdonefile,d", "create a *.done file")
//			("printrawdata,r", "print the raw data to std::out")
//			("printdebugdata,b", "print debug data to std::out")
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
		std::cout << "description: ... " << std::endl << desc << std::endl;
		return 1;
	}

	smc_driver_error_t err;
	err = smc_open(0);
	if (err != ERROR_NONE)
	{
		std::cerr << "cannot open bus driver!" << std::endl;
		return 1;
	}


	if(vm.count("triggermask"))
	{
		int temp;
		std::stringstream interpreter;
		interpreter << std::hex << vm["triggermask"].as<std::string>();
		interpreter >> temp;
		icescint_setTriggerMask(temp);
//		iceSint_setTriggerMask(vm["triggermask"].as<int>());
	}
	if(vm.count("singlesofttrigger"))
	{
		icescint_doSingleSoftTrigger();
	}
	if(vm.count("softtriggergeneratorenable"))
	{
		icescint_setSoftTriggerGeneratorEnable(vm["softtriggergeneratorenable"].as<int>());
	}
	if(vm.count("softtriggergeneratorperiod"))
	{
		icescint_setSoftTriggerGeneratorPeriod(vm["softtriggergeneratorperiod"].as<int>());
	}


	return 0;
}
