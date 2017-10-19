#include <iostream>
#include <string>

#include <boost/program_options.hpp>

#include "SlowControl.hpp"

namespace po = boost::program_options;

#define EXIT_OK 0
#define EXIT_ERROR -1

int main(int argc, char** argv)
{
	std::string server;
	int port = 9090;

	po::options_description desc("Allowed options");
	desc.add_options()
		("help,h", "show help message")
		("server", po::value<std::string>(&server)->default_value("127.0.0.1"), "thrift server address / name")
		("port", po::value<int>(&port)->default_value(9090), "server port")
	;

	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
	po::notify(vm);

	if (vm.count("help"))
	{
		std::cout << "*** icescint_slowcontrol_client - simple thrift client example | compiled " << __DATE__ << " " << __TIME__ << " ***"<< std::endl;
		std::cout << desc << "\n";
		return EXIT_ERROR;
	}

	taxi::SlowControl slowControl(server, port);

	// do some useful things here
	std::cout << "getNumberOfSamplesToRead: " << int(slowControl.getNumberOfSamplesToRead()) << std::endl;

	std::cout << "setNumberOfSamplesToRead(100)... " << std::endl;
	slowControl.setNumberOfSamplesToRead(100);

	std::cout << "getNumberOfSamplesToRead: " << int(slowControl.getNumberOfSamplesToRead()) << std::endl;

	std::cout << "setNumberOfSamplesToRead(200)... " << std::endl;
	slowControl.setNumberOfSamplesToRead(200);

	std::cout << "getNumberOfSamplesToRead: " << int(slowControl.getNumberOfSamplesToRead()) << std::endl;

	return EXIT_OK;
}

