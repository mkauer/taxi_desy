#include "boost/date_time/posix_time/posix_time.hpp"
#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>

#include <iostream>

#include "gpb/TaxiSerialTransport.hpp"

using boost::filesystem::file_size;
namespace po = boost::program_options;

int main(int argc, char** argv)
{
	using namespace std;

	int panel=0;
	string data;

	smc_open(NULL);

	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
#ifdef ARCH_AT91SAM
		    ("panel,p", po::value<int>(&panel), "select panel to use")
#endif
			("send,s", po::value<std::string>(&data), "data to be send")
		;
	po::variables_map vm;
	try {
		po::store(
			po::command_line_parser(argc, argv).options(desc).allow_unregistered().run(),
		vm);
	} catch (boost::program_options::invalid_command_line_syntax &e) {
		cout << "error: " << e.what() << endl;
		return -1;
	}

	TaxiSerialTransport transport(panel);

	data="help\r\n";

	if (vm.count("send")) {
		transport.setSendEnable(true);
		transport.write((void*)data.c_str(), data.size());
		transport.setSendEnable(false);

		while (1) {
			char buf[255];
			size_t s=sizeof(buf);
			size_t l=transport.read(buf, s);
			if (!l) {
				sleep(1);
				std::cout << "timeout" << std::endl;
			}
			std::cout << "received " << dec << l << " bytes" << std::endl;
			for (int i=0;i<l;i++) {
				std::cout << std::hex << " 0x" << ((int)buf[i]) << " '" << ((buf[i]>30)?buf[i]:' ') << "'";
			}
			for (int i=0;i<l;i++) {
				std::cout << std::hex << " 0x" << ((int)buf[i]);
			}
		}
	}

}
