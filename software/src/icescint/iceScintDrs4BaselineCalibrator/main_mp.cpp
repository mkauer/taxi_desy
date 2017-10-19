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
#include <hal/icescint.h>

#include <vector>
#include <map>

#include "hal/daqdrv.h"

#include "hal/icescint_decoder.hpp"

using namespace std;
namespace po = boost::program_options;

int verbose=0;

/*
// receive an exact amount of data
size_t daqdrv_waitForData(void* _data, size_t _size, int timeout_ms=5000)
{
	char* wrPos=(char*)_data;
	size_t dataleft=_size;
	int timeout=0;

	while (1)
	{
		if (daqdrv_isDataAvailable()) {
			void* data;
			size_t size=daqdrv_getDataEx(&data, dataleft);

			if (size>0) {
				memcpy(wrPos, data, size);
				wrPos+=size;
				dataleft-=size;
			}

			if (dataleft==0) break; // all data received, exit
		} else {
			// create a soft irq
			icescint_doIrq();
			usleep(1000);
			timeout++;
			if (timeout>=timeout_ms) break; // timeout hit, exit
		}
	}

	// return amount of received data
	return _size-dataleft;
}
*/

class Histogram16Bit
{

public:
	int m_binSize;
	typedef std::map<int,int> map_t;
	map_t m_data;

	Histogram16Bit(int _binSize=-1)
	{
		m_binSize=_binSize;
		if (m_binSize<0) m_binSize=1;
	}
	void clear()
	{
		m_data.clear();
	}
	void add(uint16_t _val)
	{
		size_t pos=(_val/m_binSize)*m_binSize;
		m_data[pos]=m_data[pos]+1;
	}

	void print()
	{
		std::vector<int> keys;
		for (map_t::iterator it=m_data.begin();it!=m_data.end();++it) {
			keys.push_back((*it).first);
		}
		std::sort(keys.begin(),keys.end());
		for (int i=0;i<keys.size();i++) {
			std::cout << "" << keys[i] << " : " << m_data[keys[i]] << std::endl;
		}
	}
};

// returns true, if a 16bit word was received
bool getNextWord(uint16_t& _data, int timeout_ms=5000)
{
	int timeout=0;

	if (daqdrv_isDataAvailable()) {
		_data=daqdrv_getNext16BitWord();
		return true;
	}

	// wait for data
	do {
		// create a soft irq
		icescint_doIrq();

		// wait
		usleep(10000);

		// check for timeout
		timeout++;
		if (timeout>(timeout_ms/10)) {
			return false;
		}
	} while(!daqdrv_isDataAvailable());

	std::cout << "waited for " << timeout * 10 << "ms to get data" << std::endl;

	// return data
	_data=daqdrv_getNext16BitWord();
	return true;
}

typedef struct {
	uint16_t header;
	uint16_t data[ICESCINT_FIFO_WIDTH_WORDS - 1];
} icescint_eventdata_t;

// waits for an DATATYPE Header, throws away everything that does not match header
// returns true, if roiStart was received successfully
// returns false on timeout
bool waitForEventDataType(uint16_t _headerType, icescint_eventdata_t& _eventdata)
{
	do
	{
		uint16_t data;

		if (!getNextWord(data)) {
			std::cerr << "waitForEventDataType error: timeout waiting for header type 0x" << _headerType << std::endl;
			return false;
		}

		if ((MASK_ICESCINT_DATATYPE&data) == (MASK_ICESCINT_DATATYPE&_headerType)) {
			_eventdata.header=data;
			break;
		}

		std::cerr << "waitForEventDataType error: header not there... 0x" << std::hex << int(data) << std::endl;
	} while(1);

	// get rest of the eventdata
	for(int j=0;j<(ICESCINT_FIFO_WIDTH_WORDS-1);j++) {
		if (!getNextWord(_eventdata.data[j])) {
			std::cerr << "getRoiStart error: timeout waiting for data word #" << std::dec << j << std::endl;
			return false;
		}
	}

	return true;
}

// waits for an DATATYPE Header, throws away everything that does not match header
// returns true, if roiStart was received successfully
// returns false on timeout
bool getRoiStart(uint16_t& _roiStart)
{
	icescint_eventdata_t eventData;
	if (!waitForEventDataType(VALUE_ICESCINT_DATATYPE_HEADER, eventData)) {
		//std::cerr << "getRoiStart error: timeout waiting for header"<< std::endl;
		return false;
	}

	_roiStart=eventData.data[7];
	return true;
}

//int getDrs4Data(int roi, uint32_t *_data)
bool getDrs4Data(int roi, std::vector< std::vector<uint32_t> > &_data, std::vector<Histogram16Bit>& _histograms)
{
	uint16_t data = 0;
	int pointer = roi;

	for(int i=0;i<0x400;i++)
	{
		icescint_eventdata_t eventData;

		if (!waitForEventDataType(VALUE_ICESCINT_DATATYPE_DSR4SAMPLING, eventData)) {
			std::cerr << "getDrs4Data error: timeout waiting" << std::endl;
			return false;
		}

		for(int j=0;j<8;j++)
		{
			_histograms[j].add(eventData.data[j]);
			_data[j][pointer] = _data[j][pointer] + eventData.data[j];
		}
		pointer = (pointer + 1) % 1024;

//		std::cout << "... done " << std::endl;
	}

	return true;
}

//---------------------------------------------

int main(int argc, char** argv)
{
	int iterations = 0;

	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
			("iterations,i", po::value<int>(&iterations)->default_value(100), "number of chip readouts")
			("clear,c", "clear fifo and ring buffers")
			("reset,r", "reset correction ram before")
			("apply,a", "apply new correction values to ram")
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

	std::vector<Histogram16Bit> histograms(8);
	std::vector< std::vector <uint32_t> > buffer(8,std::vector<uint32_t>(1024));
	std::vector< std::vector <uint32_t> > diff(8,std::vector<uint32_t>(1024));

	uint32_t currentSlot[9];
	uint16_t words = 0;
	uint16_t roi = 0;
	int ret = 0;
	int max = 0;
	int min = 0;
	int drs4MaxSamples = 0x400;

	uint16_t oldMask = icescint_getTriggerMask();
	icescint_setTriggerMask(0xff); // all channels off

	uint16_t oldNumberOfSamplesToRead = icescint_getNumberOfSamplesToRead();
	icescint_setNumberOfSamplesToRead(drs4MaxSamples);

	uint16_t oldFifoConfig = icescint_getEventFifoPacketConfig();
	icescint_setEventFifoPacketConfig(VALUE_ICESCINT_READOUT_EVENTFIFOPACKETCONFIG_DRS4SAMPLING);

	int oldIrqEnabled = icescint_isIrqEnable();
	icescint_setIrqEnable(1);

//	uint16_t oldIrqEventcountThreshold = icescint_getIrqEventcountThreshold();
//	icescint_setIrqEventcountThreshold(drs4MaxSamples);

	if (vm.count("clear")) {
		daqdrv_clearBuffers();
	}

	if (vm.count("reset"))
	{
		for(int i=0;i<1024;i++)
		{
			icescint_setCorrectionRamValue(0,i,0);
		}
	}

	std::cout << "run with " << iterations << " iterations..." << std::endl;
	for(int i=0;i<iterations;i++)
	{
		icescint_doSingleSoftTrigger();

		if (!getRoiStart(roi)) {
			std::cout << "error receiving roi" << i << std::endl;
			break;
		}
		std::cout << "iteration: " << i << "/" << iterations << " (roi: " << std::dec << roi << ")" << std::endl;
		if(!getDrs4Data(roi, buffer, histograms))
		{
			std::cout << "error receiving drs4 data in iteration " << i << std::endl;
			break;
		}
	}

	for(int i=0;i<1024;i++)
	{
		for(int j=0;j<8;j++)
		{
			diff[j][i] = buffer[j][i] / iterations;
		}
	}

	std::cout << "done" << std::endl;

	max = *std::max_element(diff[0].begin(), diff[0].end());
	std::cout << "max: " << max << std::endl;
	min = *std::min_element(diff[0].begin(), diff[0].end());
	std::cout << "min: " << min << std::endl;
	std::cout << "diff: " << max - min << std::endl;

	for(int i=0;i<1024;i++)
	{
		for(int j=0;j<8;j++)
		{
			min = *std::min_element(diff[j].begin(), diff[j].end());
			diff[j][i] = diff[j][i] - min;
		}
	}

	max = *std::max_element(diff[0].begin(), diff[0].end());
	std::cout << "max2: " << max << std::endl;

	if (vm.count("apply"))
	{
		std::cout << "applying values..." << std::endl;
		for(int i=0;i<1024;i++)
		{
//			for(int j=0;j<8;j++)
//			{
				icescint_setCorrectionRamValue(0,i, max - diff[0][i]);
//			}
		}
	}

	// diff = diff - min from diff
	// apply to ram....

	for(int i=0;i<1024;i++)
	{
		std::cout << int(diff[0][i]) << ", ";
	}
	std::cout << std::endl;

	for(int j=0;j<8;j++)
	{
		std::cout << "histogram channel " << j << std::endl;
		histograms[j].print();
	}


//	icescint_setIrqEventcountThreshold(oldIrqEventcountThreshold);
	icescint_setIrqEnable(oldIrqEnabled);
	icescint_setEventFifoPacketConfig(oldFifoConfig);
	icescint_setNumberOfSamplesToRead(oldNumberOfSamplesToRead);
	icescint_setTriggerMask(oldMask);

	return 0;
}
