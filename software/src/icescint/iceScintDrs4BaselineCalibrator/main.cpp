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
#include <boost/algorithm/string.hpp>
#include <hal/icescint.h>

#include <vector>

#include "hal/daqdrv.h"

using namespace std;
namespace po = boost::program_options;

uint16_t getNextWord(void)
{
	uint16_t data = 0;
	while(daqdrv_isDataAvailable() == 0) {usleep(10);}
	return daqdrv_getNext16BitWord();
}

int getRoiStart(uint32_t *_eventcounter)
{
	uint16_t data = 0;
	uint32_t eventcounter = 0;
	data = getNextWord();

	while(data != VALUE_ICESCINT_DATATYPE_HEADER)
	{
		std::cout << "error: header not there... 0x" << std::hex << int(data) << std::dec << std::endl;
		data = getNextWord();
	}

	eventcounter = getNextWord();
	eventcounter = (eventcounter << 16) + getNextWord();
//	std::cout << "eventcounter: " << std::hex << int(eventcounter) << std::dec << std::endl;
	*_eventcounter = eventcounter;

	for(int j=0;j<6;j++)
	{
		data = getNextWord();
	}

	return data;
}

//int getDrs4Data(int roi, uint32_t *_data)
int getDrs4Data(int roi, std::vector< std::vector<uint32_t> > &_data)
{
	uint16_t data = 0;
	int pointer = roi;

	for(int i=0;i<0x400;i++)
	{
//		std::cout << "i: 0x" << std::hex << i;
		data = getNextWord();

		if((MASK_ICESCINT_DATATYPE&data) != VALUE_ICESCINT_DATATYPE_DSR4SAMPLING)
		{
			std::cout << "error: samples not there... 0x" << std::hex << int(data) << std::dec << std::endl;
			return 1;
		}

		for(int j=0;j<8;j++)
		{
			_data[j][pointer] = _data[j][pointer] + getNextWord();
		}
		pointer = (pointer + 1) % 1024;

//		std::cout << "... done " << std::endl;
	}
	return 0;
}

//---------------------------------------------

int main(int argc, char** argv)
{
	int iterations = 0;
	std::string csvPathWrite;
	std::string csvPathRead;

	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
			("iterations,i", po::value<int>(&iterations), "number of chip readouts")
			("reset,r", "reset correction ram before")
			("apply,a", "apply new correction values to ram")
			("writecsv,w", po::value<std::string>(&csvPathWrite), "write the corection values to csv file")
			("readcsv,c", po::value<std::string>(&csvPathRead), "read the corection values from csv and apply")
			("verbose,v", "")
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
		cout << "*** drs4 baseline calibrator | " << __DATE__ << " " << __TIME__ << " ***"<< endl;
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

	daqdrv_error_t err2;
	err2 = daqdrv_open(0);
	if (err2 != DAQDRV_ERROR_NONE)
	{
		std::cerr << "cannot open daq driver!" << std::endl;
		return 1;
	}

	std::vector< std::vector <uint32_t> > buffer(8,std::vector<uint32_t>(1024));
	std::vector< std::vector <uint32_t> > diff(8,std::vector<uint32_t>(1024));

//	uint32_t currentSlot[9];
//	uint16_t words = 0;
	int roi = 0;
	int ret = 0;
	int max = 0;
	int min = 0;
	int drs4MaxSamples = 0x400;
	uint32_t eventCounter = 0;
	uint32_t oldEventCounter = 0;

	uint16_t oldMask = icescint_getTriggerMask();
	icescint_setTriggerMask(0xff); // all channels off

	uint16_t oldNumberOfSamplesToRead = icescint_getNumberOfSamplesToRead();
	icescint_setNumberOfSamplesToRead(drs4MaxSamples);

	uint16_t oldFifoConfig = icescint_getEventFifoPacketConfig();
	icescint_setEventFifoPacketConfig(VALUE_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4SAMPLING);

	int oldIrqEnabled = icescint_isIrqEnable();
	icescint_setIrqEnable(1);

	uint16_t oldIrqEventcountThreshold = icescint_getIrqEventcountThreshold();
	icescint_setIrqEventcountThreshold(drs4MaxSamples); // ??!

	uint32_t oldSoftTriggerGeneratorPeriod = icescint_getSoftTriggerGeneratorPeriod();
	icescint_setSoftTriggerGeneratorPeriod(0x1000000);

	int oldSoftTriggerGeneratorEnable = iceSint_getSoftTriggerGeneratorEnable();
	icescint_setSoftTriggerGeneratorEnable(1);

//	icescint_setSoftTriggerGeneratorEnable(1);

	if (vm.count("reset"))
	{
		std::cout << "reset all values to 0x0" << csvPathRead << std::endl;
		for(int i=0;i<1024;i++)
		{
			icescint_setCorrectionRamValue(0xff,i,0);
		}
		goto cleanUp;
	}

	if (vm.count("readcsv"))
	{
		std::cout << "read values from file: " << csvPathRead << std::endl;
		std::ifstream myfile;
		myfile.open (csvPathRead.c_str(), std::ios::out | std::ios::app );

		for(int i=0;i<1024;i++)
		{
			std::vector<std::string> result;
			std::string line;
			std::getline(myfile,line);

			std::stringstream lineStream(line);
			std::string cell;

			while(std::getline(lineStream,cell, ','))
			{
				result.push_back(cell);
			}

			int k=0;
			if (vm.count("verbose")) {std::cout << "cell: " << i << "\t";}
			for (std::vector<string>::iterator it = result.begin() ; it != result.end(); ++it)
			{
				int value;
				istringstream(*it) >> value;
				if (vm.count("verbose")) {std::cout << " " << value << ", ";}
				icescint_setCorrectionRamValue(bitValue16(k),i,value);
				k++;
			}
			if (vm.count("verbose")) {std::cout << std::endl;}
		}
		myfile.close();
		goto cleanUp;
	}

//	icescint_setIrqEnable(0);
//	iceSint_flushEventFifo();
//	daqdrv_clearBuffers();
//	icescint_setIrqEnable(1);

	if (vm.count("iterations"))
	{
		std::cout << "run with " << iterations << " iterations..." << std::endl;
		for(int i=0;i<iterations;i++)
		{
			std::cout << "\r iteration " << i << " running...";
			icescint_doSingleSoftTrigger();

			usleep(1000);
			icescint_doIrq();
			usleep(1000);

			roi = getRoiStart(&eventCounter);
			if((oldEventCounter + 1) != eventCounter)// && (oldEventCounter != 0))
			{
				std::cout << "eventcounter mismatch " << oldEventCounter << " +1  != " << eventCounter << std::endl;
			}
			oldEventCounter = eventCounter;
			std::cout << "rio: " << roi << "               " << std::flush;


			ret = getDrs4Data(roi, buffer);
			if(err != 0)
			{
				std::cout << "error in iteration " << i << std::endl;
			}
		}

		std::cout << "done" << std::endl;

	//	for(int i=0;i<1024;i++)	{std::cout << int(buffer[0][i]) << "\t, ";} std::cout << std::endl;

		int minValue = 0xffff;
		int maxValue = 0x0;
		int minPosition = 0;
		int maxPosition = 0;
		for(int i=0;i<1024;i++)
		{
			if(buffer[0][i] < minValue)
			{
				minValue = buffer[0][i];
				minPosition = i;
			}
			if(buffer[0][i] > maxValue)
			{
				maxValue = buffer[0][i];
				maxPosition = i;
			}
		}

	//	std::cout << "minPos: " << minPosition << " maxPos: " << maxPosition << ", roi: " << roi << ", delta: " << (roi-maxPosition) << std::endl;
	//	std::cout << " maxPos: " << maxPosition << ", roi: " << roi << std::endl;

		for(int i=0;i<1024;i++)
		{
			for(int j=0;j<8;j++)
			{
				diff[j][i] = buffer[j][i] / iterations;
			}
		}

		for(int j=0;j<8;j++)
		{
			max = *std::max_element(diff[j].begin(), diff[j].end());
			min = *std::min_element(diff[j].begin(), diff[j].end());

			if (vm.count("verbose")) {std::cout << "min(" << j << "): " << min << ", " << "max(" << j << "): " << max << ", " << "diff(" << j << "): " << max - min << std::endl;}
		}

		for(int j=0;j<8;j++)
		{
			max = *std::max_element(diff[j].begin(), diff[j].end());
			for(int i=0;i<1024;i++)
			{
				diff[j][i] = max - diff[j][i];
			}
		}
	}

	if (vm.count("writecsv"))
	{
		std::cout << "write values to file: " << csvPathWrite << std::endl;
		std::ofstream myfile;
		myfile.open (csvPathWrite.c_str(), std::ios::out | std::ios::app );

		for(int i=0;i<1024;i++)
		{
			for(int j=0;j<8;j++)
			{
				myfile << std::dec << diff[j][i];
				if(j<7) {myfile << ",";}
			}
			myfile << "\n";
		}
		myfile.close();
	}

	if (vm.count("apply"))
	{
		std::cout << "applying all values..." << std::endl;
		for(int j=0;j<8;j++)
		{
			for(int i=0;i<1024;i++)
			{
				icescint_setCorrectionRamValue(bitValue16(j),i, diff[j][i]);
			}
		}
	}

	if (vm.count("verbose"))
	{
		std::cout << "diff for channel 0:" << std::endl;
		for(int i=0;i<1024;i++)
		{
			std::cout << int(diff[0][i]) << "\t, ";
		}
		std::cout << std::endl;
	}

	cleanUp:
		icescint_setSoftTriggerGeneratorPeriod(oldSoftTriggerGeneratorPeriod);
		icescint_setSoftTriggerGeneratorEnable(oldSoftTriggerGeneratorEnable);
		icescint_setIrqEventcountThreshold(oldIrqEventcountThreshold);
		icescint_setIrqEnable(oldIrqEnabled);
		icescint_setEventFifoPacketConfig(oldFifoConfig);
		icescint_setNumberOfSamplesToRead(oldNumberOfSamplesToRead);
		icescint_setTriggerMask(oldMask);

	return 0;
}
