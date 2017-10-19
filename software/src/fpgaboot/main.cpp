// tool program reboot slaves

#include <iostream>
#include <string>
#include <fstream>
#include <vector>
#include <stdlib.h>

#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>
#include "hal/fpga.h"

using namespace std;
using boost::filesystem::file_size;
namespace po = boost::program_options;

#define EXIT_OK 0
#define EXIT_ERROR -1


int main(int argc, char** argv)
{
	using namespace std;

	cout << "***** fpga firmware loader" << __DATE__ << " " << __TIME__ << endl;

	string filename;
	string device;

	int 	orbitTriggerDelay;
	int 	histOrbitThreshold;
	int 	samplingMode;
	int     mode;
	int		testNr;
	unsigned int     mask;
	bool didSomething = false;

	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
			("view,v", "view current settings")
		    ("filename,f", po::value<std::string>(&filename)->default_value("/opt/firmware/defaultFirmware.bit"), "set image file to load")
			("device,d", po::value<string>(&device)->default_value("/dev/fpga0"),"set device to use for fpga configuration")
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
		return EXIT_OK;
	}

	cerr << "firmware filename: " << filename << endl;
	if (!filename.empty())
	{
		cout << "Unconfiguring fpga" << endl;
		fpga_unconfigureFirmware(device.c_str());

//		for (int i=0;i<3;i++) {
		do {
			cout << "Loading firmware from '" << filename << "' ..." << endl;
			if (!fpga_loadFirmware(filename.c_str(), device.c_str())) break;

//			if (hess1u_smi_getSystemType()!=HESS1U_SYSTEM_UNKNOWN) {
//				cout << "firmware loading successful!" << endl;
//				cout << "system firmware type is: '" << hess1u_smi_getSystemTypeName() << "'" << endl;
//				setenv(HESS1U_ENVVAR_SYSTEM_TYPE,hess1u_smi_getSystemTypeName(),1);
//				break;
//			} else {
//				cout << "ERROR: firmware loading failed!" << endl;
//			}
//		}
		} while(0);
	}
	else
	{
		cout << "no firmware loading performed." << endl;
	}

	return EXIT_OK;
}
