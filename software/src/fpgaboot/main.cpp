// tool program reboot slaves

#include <iostream>
#include <string>
#include <fstream>
#include <vector>
#include <stdlib.h>

#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>
#include "hal/fpga.h"

using boost::filesystem::file_size;
namespace po = boost::program_options;

#define EXIT_OK 0
#define EXIT_ERROR -1

//#define DEFAULT_FIRMWARE "/opt/taxi/firmware/icescint_180130_02.bit"
//#define DEFAULT_FIRMWARE "/opt/taxi/firmware/icescint_180403_00.bit"
//#define DEFAULT_FIRMWARE "/opt/taxi/firmware/icescint_180530_00.bit"
//#define DEFAULT_FIRMWARE "/opt/taxi/firmware/taxitop.bit"
//#define DEFAULT_FIRMWARE "/opt/taxi/firmware/icescint_180710_00.bit"
#define DEFAULT_FIRMWARE "/opt/taxi/firmware/uvlogger_181117_00.bit"

int main(int argc, char** argv)
{
	std::string filename;
	std::string device;

	std::string defaultMessage = std::string("load the default firmware file (") + std::string(DEFAULT_FIRMWARE) + std::string (")");

	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "print this help")
			//("view,v", "view current settings")
			("defaultFilename,d", defaultMessage.c_str())
			("filename,f", po::value<std::string>(&filename), "load a custom firmware file")
			("device", po::value<std::string>(&device)->default_value("/dev/fpga0"), "set device to use for fpga configuration")
			;

	po::variables_map vm;
	try
	{
		po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
	}
	catch (boost::program_options::invalid_command_line_syntax &e)
	{
		std::cout << "error: " << e.what() << std::endl;
		return EXIT_ERROR;
	}
	po::notify(vm);

	if (vm.count("help"))
	{
		std::cout << "*** fpgainit | compiled " << __DATE__ << " " << __TIME__ << " ***" << std::endl;
		std::cout << desc << std::endl;
		return EXIT_OK;
	}

	if (vm.count("defaultFilename"))
	{
		filename = DEFAULT_FIRMWARE;
	}
	if ((vm.count("defaultFilename") or vm.count("filename")))
	{
		if (filename.empty())
		{
			std::cout << "Filename is empty" << std::endl;
			return EXIT_ERROR;
		}
		else
		{
			std::cout << "firmware filename: " << filename << std::endl;
		}

		// TODO: check if file exists...

		std::cout << "Unconfiguring FPGA..." << std::endl;
		fpga_unconfigureFirmware(device.c_str());

		std::cout << "Loading firmware from '" << filename << "' ...";
		if (fpga_loadFirmware(filename.c_str(), device.c_str()))
		{
			std::cout << " failed!";
		}
		else
		{
			std::cout << " done";
		}
		std::cout << std::endl;
	}
	else
	{
		std::cout << "No firmware loading performed." << std::endl;
	}

	return EXIT_OK;
}
