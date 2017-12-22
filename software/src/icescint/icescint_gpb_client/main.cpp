#include "boost/date_time/posix_time/posix_time.hpp"
#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>

#include <errno.h>
#include <fcntl.h>
#include <gpb/DebugTransport.hpp>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <iostream>
#include <sstream>
#include "gpb/USBSerialTransport.hpp"
#include <fstream>

#include "hal/smc.h"

#include "gpb/TaxiSerialTransport.hpp"
#include "gpb/GPBController.hpp"
#define  error_message(MSG...) (MSG)

using namespace std;
using boost::filesystem::file_size;
namespace po = boost::program_options;



int main(int argc, char** argv)
{
	cout << "***** icescint GPB client - " << __DATE__ << " " << __TIME__ << endl;

	string filename, portname;
	int panel,lgsel,rxlbsel;
	unsigned int     mask;
	bool didSomething = false;
	double highVoltage=0;
	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
			("test,t", "test communication")
#ifdef ARCH_AT91SAM
		    ("panel,p", po::value<int>(&panel), "select panel to use")
#else
		    ("device,d", po::value<std::string>(&portname), "send pmt command")
#endif
		    ("cmd,c", po::value<std::string>(), "send pmt command")
		    ("lgsel", po::value<int>(&lgsel), "set lgsel to 0 or 1")
		    ("rxlbsel", po::value<int>(&rxlbsel), "set rxlbsel to 0 or 1")
		    ("sethv", po::value<double>(&highVoltage), "set pmt high voltage")
		    ("pon", "set pmt high voltage on")
		    ("poff", "set pmt high voltage off")
		    ("status", "request lgsel & rxlbsel status")
			("debug,d", "debug")
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

	//po::store(po::command_line_parser(argc, argv).options(desc).positional(p).run(), vm);

	po::notify(vm);

	if (vm.count("help")) {
		cout << desc << "\n";
		return 0;
	}

#ifdef ARCH_AT91SAM

	smc_open(NULL);

	if (!vm.count("panel") || panel<0 || panel>7) {
		cerr << "you must select a panel 0..7 !" << endl;
		return 0;
	}

	TaxiSerialTransport transportSerial(panel);
#else
	USBSerialTransport transport(portname.c_str());
#endif

	DebugTransport transportDbg(&transportSerial);

	IIOTransport* transport;

	if (vm.count("debug")) transport=&transportDbg;
	else transport=&transportSerial;

	GPBPacketProtocol packetProtocol(transport);

	GPBController& client=getGPBController(panel);
	//&packetProtocol);

	GPBController::error_t err;

	// requests software version
	// returns EOK on success and
	// returns in version bit 15..8 major version and in bit 7..0 minor version

	client.initialize(true);

	uint16_t version=0;
	err=client.getVersion(version);
	if (err!=GPBController::EOK) {
		std::cerr << "error retrieving firmware version from panel" << std::endl;
	} else {
		if (version<0x0101) {
			std::cerr << "error version not supported : " << std::hex << "0x" << version << " (required > 0x0101)" << std::endl;
		}
	}

	if (vm.count("test")) {
		std::cout << "testing connection... ";
		err=client.testCmd();
		if (err==GPBController::EOK) {
			std::cout << "test ok!" << std::endl;
			didSomething=true;
		} else {
			std::cout << "error: " << client.toString(err) << std::endl;
			return 1;
		}
		return 0;
	}

	if (vm.count("cmd")) {
		std::cout << "sending pmt command... ";
		std::string reply;
		err=client.sendPmtCommand(vm["cmd"].as<std::string>(), reply);
		if (err==GPBController::EOK) {
			std::cout << "reply: " << reply << std::endl;
			didSomething=true;
		} else {
			std::cout << "error: " << client.toString(err) << std::endl;
			return 1;
		}
		return 0;
	}

	if (vm.count("lgsel")) {
		if (lgsel<0 or lgsel>1) {
			std::cerr << "lgsel must be 0 or 1" << std::endl;
			return 1;
		}
		std::cout << "sending lgsel value... ";
		err=client.setLgSel(lgsel);
		if (err==GPBController::EOK) {
			std::cout << "set lgsel = " << lgsel << std::endl;
			didSomething=true;
		} else {
			std::cout << "error: " << client.toString(err) << std::endl;
			return 1;
		}
		return 0;
	}

	if (vm.count("rxlbsel")) {
		if (rxlbsel<0 or rxlbsel>1) {
			std::cerr << "rxlbsel must be 0 or 1" << std::endl;
			return 1;
		}
		std::cout << "sending rxlbsel value... ";
		if (!client.setRxlbSel(rxlbsel)) {
			std::cout << "set rxlbsel = " << rxlbsel << std::endl;
			didSomething=true;
		} else {
			std::cout << "error: " << client.toString(err) << std::endl;
			return 1;
		}
		return 0;
	}

	if (vm.count("sethv")) {
		std::cout << "sending pmt hv value... ";
		if (!client.pmt_setHV(highVoltage)) {
			std::cout << "set hv value = " << highVoltage << std::endl;
			didSomething=true;
		} else {
			std::cout << "error: " << client.toString(err) << std::endl;
			return 1;
		}
	}

	if (vm.count("pon") || vm.count("poff") ) {
		bool onoff=vm.count("pon");
		std::cout << "sending pmt power... ";
		if (!client.pmt_setHV(highVoltage)) {

			std::cout << "set pmt power = " << (onoff?"on":"off") << std::endl;
			didSomething=true;
		} else {
			std::cout << "error: " << client.toString(err) << std::endl;
			return 1;
		}
	}

	if (vm.count("status")) {
		bool rxlbsel,lgsel;
		std::cout << "request status... " << std::endl;
		err=client.getStatus(lgsel, rxlbsel);
		if (err==GPBController::EOK) {
			std::cout << "lgsel        = " << lgsel   << std::endl;
			std::cout << "rxlbsel      = " << rxlbsel << std::endl;
			didSomething=true;
		} else {
			std::cout << "error: " << client.toString(err) << std::endl;
			return 1;
		}

		int temp;
		err=client.pmt_getTemperature(temp);
		if (err==GPBController::EOK) {
			std::cout << "temperature  = " << temp << std::endl;
			didSomething=true;
		} else {
			std::cout << "error: " << client.toString(err) << std::endl;
			return 1;
		}

		return 0;
	}

	if (!didSomething) {
		std::cerr << "no command defined. run with --help to get all options." << std::endl;
		return 1;
	} else {
		return 0;
	}

}
