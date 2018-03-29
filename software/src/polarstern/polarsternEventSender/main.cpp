#include <boost/program_options.hpp>
#include <algorithm>
#include <iostream>
#include <sstream>
#include <iomanip>
#include <string.h>
#include "hal/smc.h"
#include "zmq.hpp"
#include <fstream>
#include <ctime>
#include <time.h>

#define BASE_TAXI_READOUT						0x0000
#define OFFS_TAXI_READOUT_EVENTFIFO				0x20
#define OFFS_TAXI_READOUT_EVENTFIFOWORDCOUNT	0x22

namespace po = boost::program_options;

int verbose = 0;
const int oneDay = 60*60*24;
const int numberOfSlots = 100;

#define TAXI_FIFO_WIDTH_WORDS 23

// read data one-by-one directly from fifo, bypass the driver completly and irq
size_t readEventsDirect(uint16_t* _data, size_t _numEvents, int _sleepValue)
{
	int offs_wr = 0;
	size_t eventSize = 0;
	int words;
	int events = 0;

	words = IORD_16DIRECT(BASE_TAXI_READOUT, OFFS_TAXI_READOUT_EVENTFIFOWORDCOUNT);

	while(events < _numEvents)
	{
		if((words == 0) && (_sleepValue > 0)){usleep(_sleepValue);}
		for (int i=0;i<words;i++)
		{
			for (int j=0;j<TAXI_FIFO_WIDTH_WORDS;j++)
			{
				_data[offs_wr] = IORD_16DIRECT(BASE_TAXI_READOUT, OFFS_TAXI_READOUT_EVENTFIFO);
				offs_wr++;
			}
			eventSize += TAXI_FIFO_WIDTH_WORDS*2;
			events++;
		}
		words = std::min((size_t)IORD_16DIRECT(BASE_TAXI_READOUT, OFFS_TAXI_READOUT_EVENTFIFOWORDCOUNT),_numEvents-events);
	}

	return eventSize;
}

// try to empty the bugy fifo
void flushFifo(void)
{
//	for (int ev = 0; ev < 5000*23*10; ev++)
//	{
//		IORD_16DIRECT(BASE_TAXI_READOUT, OFFS_TAXI_READOUT_EVENTFIFO);
//	}
	IOWR_16DIRECT(BASE_TAXI_READOUT, OFFS_TAXI_READOUT_EVENTFIFOWORDCOUNT, 0x0);
}

// generate test data
size_t testData(uint16_t* _data, size_t _numEvents, int _timeOutSecound)
{
	int offs_wr = 0;
	size_t event_size = 0;
	for (int ev = 0; ev < _numEvents; ev++)
	{
		for (int i = 0; i < 32; i++)
		{
			_data[offs_wr] = i + 0x100 * ev;
			offs_wr++;
			event_size++;
		}
	}

	sleep(_timeOutSecound);

	return event_size;
}

void _freeMessage(void *data, void *hint)
{
	// do nothing
}

//---------------------------------------------
std::string getTimeString(struct tm* _time)
{
	char timeBuffer[100];
	strftime(timeBuffer,sizeof(timeBuffer),"%Y-%m-%d_%H-%M-%S",_time);
	std::string timeString(timeBuffer);

	return timeString;
}

std::string getTimeString(time_t _time)
{
	struct tm tmp = *localtime(&_time);
	return getTimeString(&tmp);
}

std::string getTimeStringUTC(time_t _time)
{
	std::stringstream ss;
	ss << int(_time);
	return ss.str();
}

time_t getNextDayTime(int _newFileTimeOffset, time_t _rawtime_now)
{
	time_t nextDay;

	if(_newFileTimeOffset < 0) {_newFileTimeOffset = 0;}
	_newFileTimeOffset = _newFileTimeOffset % oneDay;

	nextDay = ((_rawtime_now / oneDay) + 1) * oneDay + _newFileTimeOffset;

	return nextDay;
}

std::string getPath(time_t _time, std::string & _newFilePath)
{
	std::string path;
	path = _newFilePath + std::string("eventData_") + getTimeStringUTC(_time) + std::string("_") + getTimeString(_time) + std::string(".bin");

	return path;
}

void getNextFileEnd(struct tm * _timeFileEnd, int _newFileTime, time_t * _rawtime_end)
{
	time_t rawtime_now = mktime(_timeFileEnd);
	if(_newFileTime < 0) {_newFileTime = 0;}
	_timeFileEnd->tm_hour = 0;
	_timeFileEnd->tm_min = 0;
	_timeFileEnd->tm_sec = _newFileTime;
	*_rawtime_end = mktime(_timeFileEnd);
	if(rawtime_now > *_rawtime_end)
	{
		_timeFileEnd->tm_mday = _timeFileEnd->tm_mday + 1;
		*_rawtime_end = mktime(_timeFileEnd);
	}

}
//---------------------------------------------


void readAndSendData(int _port, size_t _numEvents, int _testData, int _sleepValue, int _newFileTimeout, std::string & _newFilePath, int _writeFile, int _newFileTime, int _createDoneFile)
{
//	uint16_t buffer[4][5000 * TAXI_FIFO_WIDTH_WORDS];
	uint16_t* buffer = (uint16_t*)malloc(TAXI_FIFO_WIDTH_WORDS*2 * _numEvents * numberOfSlots);
	size_t eventSize = 0;

	zmq::context_t m_context;

	zmq::socket_t publisher(m_context, ZMQ_PUB);
	std::ostringstream connectAddress;

	connectAddress << "tcp://*:" << _port;

	if (verbose) std::cout << "publishing on " << connectAddress.str() << std::endl;

	publisher.bind(connectAddress.str().c_str());

	//flushFifo();

	double count = 0;

	time_t rawtime_now;
	time_t rawtime_old;
	time_t rawtime_end;
	struct tm timeFileEnd;
	int seconds;
	int result;
	int slot = 0;

	std::ofstream myfile;
	std::string currentFileName;

	rawtime_old = time(NULL);
	rawtime_now = time(NULL);

	if(_writeFile)
	{
		currentFileName = getPath(rawtime_now, _newFilePath); // ## filename is not always ok....
		myfile.open(currentFileName.c_str(), std::ios::out | std::ios::app | std::ios::binary);
		std::cout << "writing to file " << getPath(rawtime_now, _newFilePath) << "..." << std::endl;
	}

	if(_newFileTime > -1)
	{
		rawtime_end = getNextDayTime(_newFileTime,rawtime_now);
		std::cout << "file will end at UTC " << getTimeString(rawtime_end) << std::endl;
	}

	while (1)
	{
		slot++;
		slot = slot % numberOfSlots;

		if (_testData == 1)
		{
			eventSize = testData(buffer+(slot*TAXI_FIFO_WIDTH_WORDS*_numEvents), _numEvents, 1);
		}
		if (_testData == 0)
		{
			eventSize = readEventsDirect(buffer+(slot*TAXI_FIFO_WIDTH_WORDS*_numEvents), _numEvents, _sleepValue);
		}

		zmq::message_t msg(buffer+(slot*TAXI_FIFO_WIDTH_WORDS*_numEvents), eventSize, &(_freeMessage), NULL);

		if(_writeFile)
		{
			myfile.write((char*)(buffer+(slot*TAXI_FIFO_WIDTH_WORDS*_numEvents)), eventSize);

			rawtime_now = time(NULL);
			seconds = difftime(rawtime_now, rawtime_old);

			if(((_newFileTime > -1) && (rawtime_now > rawtime_end)) || ((seconds >= _newFileTimeout) && (_newFileTimeout > 0)))
			{
				rawtime_end = rawtime_end + oneDay;

				myfile.close();
				std::cout << "finished writing" << currentFileName << std::endl;

				if(_createDoneFile)
				{
					currentFileName.replace(currentFileName.end()-3,currentFileName.end(),"done").c_str();
					myfile.open(currentFileName.c_str(), std::ios::out | std::ios::app | std::ios::binary);
					myfile.close();
				}

				currentFileName = getPath(rawtime_now, _newFilePath);
				myfile.open(currentFileName.c_str(), std::ios::out | std::ios::app | std::ios::binary);
				std::cout << "writing to file " << currentFileName << "..." << std::endl;

				if((seconds >= _newFileTimeout) && (_newFileTimeout > 0))
				{
					rawtime_old = rawtime_now;
				}
			}
		}

		if (verbose)
		{
			std::cout << "(" << count << "): " << eventSize << " Bytes send" << std::endl;
			count++;

			std::cout << "now: " << rawtime_now << ", end: " << rawtime_end << std::endl;
		}

		// send data
		if (!publisher.send(msg))
		{
			std::cerr << "error sending data!" << std::endl;
		}
	}
	if(_writeFile)
	{
		myfile.close();
	}

	free(buffer);
}

int main(int argc, char** argv)
{

	int eventsPerIrq;
	int period;
	int samples;
	std::string mode;
	std::string server;
	int port;
	int count = 0;
	int testData = 0;
	int numberOfSamples = 0;
	int sleepValue = 0;
	int newFileTimeout = 0;
	int newFileTime = 0;
	std::string newFilePath;
	int writeFile = 0;
	int createDoneFile = 0;

	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
			("initialize,i", "flush the fifo before start")
			("testdata,t", po::value<int>(&testData)->default_value(0), "no event data is send but test data")
			("verbose,v", "guess what it means")
			("port,p", po::value<int>(&port)->default_value(10011), "server port data is send to")
			("count,c", po::value<int>(&count)->default_value(1), "number of events to read per zmq packet")
			("numberofsamples,n", po::value<int>(&numberOfSamples)->default_value(1), "number of samples to read per event")
			("usleep,u", po::value<int>(&sleepValue)->default_value(100), "")
			("newfiletimeout,f", po::value<int>(&newFileTimeout)->default_value(-1), "new file will be created after [sec]")
			("newfiletime,m", po::value<int>(&newFileTime)->default_value(-1), "new file will be created after [sec] from UTC midnight")
			("newfilePath,a", po::value<std::string>(&newFilePath)->default_value("/data/"), "new file will be created here")
			("writefile,w", "write to file if true")
			("createdonefile,d", "create a *.done file")
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
		std::cout << "description: runs tests with the test generator to test irq, fifo and network sending" << std::endl << "(compiled " << __DATE__ << " " << __TIME__ << ")" << std::endl << desc
				<< std::endl;
		return 1;
	}

	smc_driver_error_t err;

	err = smc_open(0);
	if (err != ERROR_NONE)
	{
		std::cerr << "cannot open bus driver!" << std::endl;
		return 1;
	}

	verbose = vm.count("verbose");
	writeFile = vm.count("writefile");

	if (vm.count("initialize"))
	{
		std::cout << "clear fifo..." << std::endl;
		flushFifo();
		//IOWR_16DIRECT(0x00, 0x08, numberOfSamples);
		//IOWR_16DIRECT(0x00, 0x22, 0xffff);
	}

	if (vm.count("createdonefile")) {createDoneFile = 1;}

	readAndSendData(port, count*numberOfSamples, testData, sleepValue, newFileTimeout, newFilePath, writeFile, newFileTime, createDoneFile);

	return 0;
}
