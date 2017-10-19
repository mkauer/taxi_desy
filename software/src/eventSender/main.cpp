#include <boost/program_options.hpp>
#include <algorithm>
#include <iostream>
#include <sstream>
#include <iomanip>
#include <string.h>
#include "common/zmq.hpp"
#include <fstream>
#include <ctime>
#include <time.h>

#include "hal/daqdrv.h"

namespace po = boost::program_options;

int verbose = 0;

// dummy for zmq message to support zero message copy
void _freeMessage(void *data, void *hint)
{
	// do nothing
}

void sendDataLoop(int _port )
{
	zmq::context_t m_context;

	zmq::socket_t publisher(m_context, ZMQ_PUB);
	std::ostringstream connectAddress;

	connectAddress << "tcp://*:" << _port;

	if (verbose) std::cout << "publishing on " << connectAddress.str() << std::endl;

	publisher.bind(connectAddress.str().c_str());

	uint32_t count = 0;

	try {
		while (1)
		{
			if (daqdrv_waitForIrq(5000)==DAQDRV_ERROR_NONE) {
				if (verbose)
				{
					std::cout << "irq!"  << std::endl;
				}
				void* data=0;
				do {
					size_t size=daqdrv_getData(&data);
					if (!size) break;
					zmq::message_t msg(data, size, &(_freeMessage), NULL);

					if (verbose)
					{
						std::cout << "(" << count << "): " << size << " Bytes send" << std::endl;
						count++;
					}

					// send data
					if (!publisher.send(msg))
					{
						std::cerr << "error sending data!" << std::endl;
					}
				} while(1);
			} else {
				if (verbose) std::cerr << "irq timeout!" << std::endl;
			}
		}
	} catch (zmq::error_t& e) {
		std::cerr << "zmq sender exception: " << e.what() << std::endl;
	}
}

int main(int argc, char** argv)
{
	int port;

	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
			("initialize,i", "clear buffers before start")
			("verbose,v", "increase verbosity")
			("port,p", po::value<int>(&port)->default_value(10011), "local zmq publishing server port")
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
		std::cout << "description: generic event sender that sends data acquired from daqdrv via zmq publisher" << std::endl << "(compiled " << __DATE__ << " " << __TIME__ << ")" << std::endl << desc
				<< std::endl;
		return 1;
	}

	daqdrv_error_t err;

	err = daqdrv_open(0);
	if (err != DAQDRV_ERROR_NONE)
	{
		std::cerr << "error: cannot open daq driver !" << DAQDRV_DEVICE << std::endl;
		return -1;
	}

	if (vm.count("verbose"))
	{
		verbose = 1;
	}

	if (vm.count("initialize"))
	{
		std::cout << "clear all buffers and fifo" << std::endl;
		daqdrv_clearBuffers();
	}

	sendDataLoop(port);

	return 0;
}
