/*
 * fpga.cpp
 *
 *  Created on: 24.07.2014
 *      Author: marekp
 */

#include <string>
#include <fstream>
#include "string.h"
#include <boost/filesystem.hpp>
#include "fpga.h"

#define DEFAULT_FPGA_DEVICE 	"/dev/fpga0"
#define DEFAULT_FPGA_FIRMWARE 	"/etc/firmware/default.rbf"

// writes some garbage to unconfigure the fpga
// returns 0 on success
// returns 1 on error openeing the device
int fpga_unconfigureFirmware(const char* _device)
{
	const char* device=_device?_device:DEFAULT_FPGA_DEVICE;
	std::ofstream fout;
	fout.open(device, std::fstream::binary);

	if (!fout) {
		return 1;
	}

	int bufsize=0x10;
	char buf[0x1000];
	memset(buf,0xff,bufsize);

	fout.write(buf,bufsize);

	fout.close();

	sleep(1);

	return 0;
}

// copyies the file into the fpga device
int fpga_loadFirmware(const char* _firmware, const char* _device)
{

	const char* device=_device?_device:DEFAULT_FPGA_DEVICE;
	const char* firmware=_firmware?_firmware:DEFAULT_FPGA_FIRMWARE;

	std::ifstream fin;
	fin.open(firmware, std::fstream::binary);

	if (!fin) {
		return 1;
	}
	size_t finsize=boost::filesystem::file_size(firmware);

	std::ofstream fout;
	fout.open(device, std::fstream::binary);

	if (!fout) {
		return 1;
	}

	int bufsize=0x10000;
	char buf[0x10000];

	using namespace std;

	size_t totalBytes=0;
	while(!fin.eof()) {

		fin.read(buf,bufsize);
		size_t bytesRead;
		if (fin) bytesRead=bufsize;
		else bytesRead=fin.gcount();

		totalBytes+=bytesRead;
		fout.write(buf,bytesRead);
	}
	fin.close();
	fout.close();

	return 0;
}

//// load firmware
//bool configureFpga(std::string& filename, std::string& device)
//{
//	unconfigureFirmware(device);
//
//	// try 3 times
//	for (int i=0;i<3;i++) {
//		if (!loadFirmware(filename, device)) return false;
//		if (hess1u_smi_getSystemType()!=HESS1U_SYSTEM_UNKNOWN) {
//			return true;
//		}
//	}
//
//	return false;
//}

