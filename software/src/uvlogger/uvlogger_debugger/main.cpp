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
#include <hal/uvlogger.h>

#include <bitset>
#include <boost/algorithm/string/replace.hpp>

#include <ctime>
#include <time.h>

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

void i2c(void)
{

}

void uvlogger_setRegisterx(uint16_t _a, uint16_t _b)
{
	uvlogger_setRegister(_a,_b);
	std::cout << std::hex << int(_b) << std::endl;
}

int main(int argc, char** argv)
{
	int channel = -1;
	int hvValue = -1;

	po::options_description desc("Allowed options");
	desc.add_options()
		("help,h", "")
		("i2c,i", "...")
		("mainBoardTmp10x,t", "...")
		("flasherBoardTmp10x,u", "...")
		("dps310,d", "...")
		("hvdac,v", po::value<int>(&hvValue) ,"12 bit value")
		("channel,c", po::value<int>(&channel)->default_value(-1), "[0..7]")
		("comm500k", "...")
		("comm375k", "...")
		("comm250k", "...")
		("comm150k", "...")
		("comm125k", "...")
		("comm100k", "...")
		("comm50k", "...")
		("comm25k", "...")
		("comm180mv", "...")
		("comm150mv", "...")
		("comm120mv", "...")
		("comm90mv", "...")
		("comm60mv", "...")
		("comm24mv", "...")
		("comm12mv", "...")
		("comm6mv", "...")
//		("debug,g", "...")
//		("irigb,i", "print irig-b information if available")
//		("gps,g", "print gps information if available")
//		("temperature,t", po::value<int>(), "print tmp05 temperature in °C (sensor is on the taxi pcb) the argument is the number of measurements")
//		("now,n", "show the actual white rabbit time")
//		("", po::value<int>(), "")
		;

	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
	po::notify(vm);

	if(vm.count("help"))
	{
		std::cout << "*** iceScintDebugger | " << __DATE__ << " | " << __TIME__ << " ***" << std::endl;
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

	if(vm.count("mainBoardTmp10x"))
	{
		int temp = uvlogger_getTemperatureMainBoardTmp10x();

//		std::cout << "temp: " << int(temp) << " -> 0x" << std::hex << int(temp) << std::endl;
		std::cout << "main board temperature: " << std::dec << 1.0/16*temp << "^C" << std::endl;
		return EXIT_OK;
	}

	if(vm.count("flasherBoardTmp10x"))
	{
		int temp = uvlogger_getTemperatureFlasherBoardTmp10x();

//		std::cout << "temp: " << int(temp) << " -> 0x" << std::hex << int(temp) << std::endl;
		std::cout << "flasher board temperature: " << std::dec << 1.0/16*temp << "^C" << std::endl;
		return EXIT_OK;
	}

	if(vm.count("dps310"))
	{
		int temp = 0;
		uint16_t i2cAddressW = (0x77<<1);
		uint16_t i2cAddressR = (0x77<<1)+1;
		float c0 = 0;
		float c1 = 0;
		float c00 = 0;
		float c01 = 0;
		float c10 = 0;
		float c11 = 0;
		float c20 = 0;
		float c21 = 0;
		float c30 = 0;

		do
		{
			uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, OFFS_UVLOGGER_I2C_BASE_A, i2cAddressW, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
			uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0x8,0);
			uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, i2cAddressR, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
			temp = uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));
			std::cout << "addr 0x8: 0x"<< std::hex << int(temp) << std::endl;
		}while((temp & 0xc0)!=0xc0);

		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, i2cAddressW, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0x10,0);
		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, i2cAddressR, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
		temp = uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		c0 = temp >> 12;
		c1 = temp & 0xfff;

		temp = uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		c00 = temp >> 4;

		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		c10 = temp & 0xfffff;

		temp = uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		c01 = temp;

		temp = uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		c11 = temp;

		temp = uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		c20 = temp;

		temp = uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		c21 = temp;

		temp = uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));
		c30 = temp;

//		std::cout << "c0: "<< std::dec << c0 << std::endl;
//		std::cout << "c1: "<< std::dec << c1 << std::endl;

		if(c0>((1<<11)-1)) {c0 = c0-(1<<12);}
		if(c1>((1<<11)-1)) {c1 = c1-(1<<12);}
		if(c00>((1<<19)-1)) {c00 = c00-(1<<20);}
		if(c10>((1<<19)-1)) {c10 = c10-(1<<20);}
		if(c01>((1<<15)-1)) {c01 = c01-(1<<16);}
		if(c11>((1<<15)-1)) {c11 = c11-(1<<16);}
		if(c20>((1<<15)-1)) {c20 = c20-(1<<16);}
		if(c21>((1<<15)-1)) {c21 = c21-(1<<16);}
		if(c30>((1<<15)-1)) {c30 = c30-(1<<16);}

//		P comp (Pa) = c00 + P raw_sc *(c10 + P raw_sc *(c20+ P raw_sc *c30)) + T raw_sc *c01 + T raw_sc *P raw_sc *(c11+P raw_sc *c21)

//		std::cout << "new c0: "<< std::dec << c0 << std::endl;
//		std::cout << "new c1: "<< std::dec << c1 << std::endl;

		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, i2cAddressW, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0x8,0);
		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0x2, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));

		do
		{
			usleep(100);
			uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, i2cAddressW, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
			uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0x8,0);
			uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, i2cAddressR, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
			temp = uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));
			std::cout << "addr 0x8: 0x"<< std::hex << int(temp) << std::endl;
		}while(!(temp & bitValue32(5)));

		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, i2cAddressW, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0x8,0);
		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0x1, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));

		do
		{
			usleep(100);
			uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, i2cAddressW, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
			uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0x8,0);
			uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, i2cAddressR, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
			temp = uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));
			std::cout << "addr 0x8: 0x"<< std::hex << int(temp) << std::endl;
		}while(!(temp & bitValue32(4)));

		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, i2cAddressW, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,0);
		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, i2cAddressR, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
		temp = uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		std::cout << "p: " << std::dec << int(temp) << " -> 0x"<< std::hex << int(temp) << std::endl;
		double pressure = temp;

		temp = uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDACK));
		temp = temp << 8;
		temp = temp + uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0,bitValue16(BIT_UVLOGGER_I2C_CONTROL_DIRECTION)|bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));
		std::cout << "t: " << std::dec << int(temp) << " -> 0x"<< std::hex << int(temp) << std::endl;
		double temperature = temp;

		pressure = (pressure/524288);
		temperature = (temperature/524288);

		pressure = c00 + pressure*(c10 + pressure * (c20 + pressure * c30)) + temperature * c01 + temperature * pressure * (c11+pressure*c21);
		temperature = 0.5*c0 + temperature*c1;

		std::cout << "temperature: "<< std::dec << temperature << "^C" << std::endl;
		std::cout << "pressure: "<< std::dec << pressure << "Pa" << std::endl;

		return EXIT_OK;
	}

	if(vm.count("hvdac"))
	{
		uint16_t i2cAddressW = (0x48<<1);
		uint16_t i2cAddressR = (0x48<<1)+1;

		if((channel == -1) || (hvValue == -1))
		{
			std::cout << "no channel given" << std::endl;
			return EXIT_OK;
		}
		channel = channel & 0xf;

		hvValue = hvValue & 0xfff;

		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, i2cAddressW, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTART));
		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, 0x30+channel, 0);
		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, hvValue>>4, 0);
		uvlogger_i2c_transferPacket(OFFS_UVLOGGER_I2C_BASE_A, (hvValue<<4)&0xff, bitValue16(BIT_UVLOGGER_I2C_CONTROL_SENDSTOP));

		return EXIT_OK;
	}

	int t = 0;
//	int v=0;
//	int b=0;
//	if(vm.count("comm180mv") != 0 ||
//			vm.count("comm150mv")  != 0 ||
//			vm.count("comm120mv") != 0 ||
//			vm.count("comm90mv") != 0 ||
//			vm.count("comm60mv") != 0 ||
//			vm.count("comm24mv") != 0 ||
//			vm.count("comm12mv") != 0 ||
//			vm.count("comm6mv")){v=1;}
//
//	if(vm.count("comm500k") != 0 ||
//			vm.count("comm375k") != 0 ||
//			vm.count("comm250k") != 0 ||
//			vm.count("comm150k") != 0 ||
//			vm.count("comm125k") != 0 ||
//			vm.count("comm100k") != 0 ||
//			vm.count("comm50k") != 0 ||
//			vm.count("comm25k")){b=1;}
//
//	if(v==1 && b==0){std::cout << "no baudrate given" << std::endl;return EXIT_OK;}
//	if(v==0 && b==1){std::cout << "no voltage given" << std::endl;return EXIT_OK;}
//	if(v==1 && b==1)
//	{
		if(vm.count("comm180mv")) {t=t|0x38; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
		if(vm.count("comm150mv")) {t=t|0x30; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
		if(vm.count("comm120mv")) {t=t|0x28; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
		if(vm.count("comm90mv")) {t=t|0x20; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
		if(vm.count("comm60mv")) {t=t|0x18; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
		if(vm.count("comm24mv")) {t=t|0x10; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
		if(vm.count("comm12mv")) {t=t|0x08; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
		if(vm.count("comm6mv")) {t=t|0x00; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module

		if(vm.count("comm500k")) {t=t|0x07; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
		if(vm.count("comm375k")) {t=t|0x06; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
		if(vm.count("comm250k")) {t=t|0x05; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
		if(vm.count("comm150k")) {t=t|0x04; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
		if(vm.count("comm125k")) {t=t|0x03; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
		if(vm.count("comm100k")) {t=t|0x02; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
		if(vm.count("comm50k")) {t=t|0x01; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
		if(vm.count("comm25k")) {t=t|0x00; uvlogger_setRegisterx(0xd026, t);} // ## hack for the comm module
//	}
//
//	if(vm.count("temperature"))
//	{
//		int iter = vm["temperature"].as<int>();
//		if(iter < 1) {iter = 1;}
//		float temp = 0;
//		for(int i=0;i<iter;i++)
//		{
//			common_doTmp05StartConversion();
//			while(common_isTmp05Busy()) {usleep(1000*10);}
//			temp = temp + common_getTmp05Temperature();
//		}
//		std::cout << "tmp05: " << temp/iter << "°C" << std::endl;
//		return EXIT_OK;
//	}

	return EXIT_OK;
}
