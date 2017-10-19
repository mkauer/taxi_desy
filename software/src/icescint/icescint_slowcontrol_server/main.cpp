#include <hal/icescint.h>
#include <hal/icescint_panelGeneralPurposeBoard.hpp>

#include <iostream>
#include <string>

#include <boost/program_options.hpp>

#include "icescint_slowcontrolHandler.hpp"

using namespace ::apache::thrift;
using namespace ::apache::thrift::protocol;
using namespace ::apache::thrift::transport;
using namespace ::apache::thrift::server;

using boost::shared_ptr;

using namespace ::taxi;

namespace po = boost::program_options;

#define EXIT_OK 0
#define EXIT_ERROR -1

int main(int argc, char **argv)
{
	int port = 9090;
	bool debug = false;

	po::options_description desc("Allowed options");
	desc.add_options()("help,h", "show help message")("port,p", po::value<int>(&port)->default_value(9090), "listen to port")("debug,d", po::value<bool>(&debug)->default_value(false),
			"if true the server will not send commands to the FPGA but print the action");

	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
	po::notify(vm);

	if (vm.count("help"))
	{
		std::cout << "*** icescint_slowcontrol_server - simple thrift server example | compiled " << __DATE__ << " " << __TIME__ << " ***" << std::endl;
		std::cout << desc << "\n";
		return EXIT_ERROR;
	}

	smc_open(NULL);

	shared_ptr<icescint_slowcontrolHandler> handler(new icescint_slowcontrolHandler(debug));
	shared_ptr<TProcessor> processor(new icescint_slowcontrolProcessor(handler));
	shared_ptr<TServerTransport> serverTransport(new TServerSocket(port));
	shared_ptr<TTransportFactory> transportFactory(new TBufferedTransportFactory());
	shared_ptr<TProtocolFactory> protocolFactory(new TBinaryProtocolFactory());

	TSimpleServer server(processor, serverTransport, transportFactory, protocolFactory);
	server.serve();

	smc_close();
	return EXIT_OK;
}

