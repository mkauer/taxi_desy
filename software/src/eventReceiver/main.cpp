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
#include "hal/icescint_defines.h"

//#include "common/icescint_validator.hpp"
#include "common/zmq.hpp"

using namespace std;
namespace po = boost::program_options;

int verbose = 0;

//#define ICESCINT_FIFO_WIDTH_WORDS 9
const int oneDay = 60*60*24;

// read data one-by-one directly from fifo, bypass the driver completly and irq
void readAndPrintEventsDirect(uint16_t* _data, size_t _words, int _fifoWidthWords, int _dec)
{
	size_t events = _words / _fifoWidthWords;

	for (int ev = 0; ev < events; ev++)
	{
		std::cout << std::dec << ev << ".event: ";
		std::cout << "(fifo) [ ";

		for (int i = 0; i < _fifoWidthWords; i++)
		{
			int data = _data[i + ev * _fifoWidthWords];
			if (_dec == 1)
			{
				std::cout << "" << std::setw(6) << std::dec << data << " ";
			}
			else
			{
				std::cout << "" << std::setfill('0') << std::setw(4) << std::hex << data << " ";
			}
		}

		std::cout << "]" << std::endl;
	}

	return;
}

//int getEvent(uint16_t* _data, uint32_t* _eventCounter, size_t* _words, size_t _fifoWidthWords)
//{
//	uint32_t eventCounter = 0;
//	int length = 0;
//	int error = 0;
//
//	*_words = 0;
//
//	if(( *(_data+0) == 0x1000) || (*(_data+0) == 0x2000) || (*(_data+0) == 0x3000) || (*(_data+0) == 0x4000) || (*(_data+0) == 0x5000) || (*(_data+0) == 0x6000) || (*(_data+0) == 0x7000))
//	{
//		if( *(_data+0) == 0x1000)
//		{
//			eventCounter = *(_data+1);
//			eventCounter = eventCounter << 16;
//			eventCounter = eventCounter + *(_data+2);
//
//			if(((*_eventCounter+1)%0x100000000) != eventCounter)
//			{
//				std::cout << "eventCounter mismatch: " << int(*_eventCounter) << "+1 != " << int(eventCounter) << std::endl;
//				error += eventCounter - (*_eventCounter+1)%0x100000000;
//			}
//			*_eventCounter = eventCounter;
//		}
//
//		length = 1;// *(_data+3);
//		*_words += _fifoWidthWords;
//
////		for(int i=1;i<length;i++)
////		{
////			if(*(_data+i*ICESCINT_FIFO_WIDTH_WORDS) != (0xc000+i-1))
////			{
//////				error++;
////			}
////
////			for (int j=0;j<8;j++)
////			{
////				if(*(_data+i*ICESCINT_FIFO_WIDTH_WORDS+j+1) != ((i-1)*8+j))
////				{
//////					error++;
////				}
////			}
////			*_words += ICESCINT_FIFO_WIDTH_WORDS;
////		}
//	}
//	else
//	{
//		std::cout << "error: unknown packet type" << std::endl;
//	}
//
//	if(error){error = 1;}
//
//	return error;
//}

//int readAndValidateEventsDirect(uint16_t* _data, size_t _words, uint32_t* _eventCounter_old, int* _okEvents, int* _errorEvents)
//{
//	int ret = 0;
//	int error = 0;
//	int okEvents = 0;
//	int errorEvents = 0;
//	size_t words = 0;
//	size_t allWords = 0;
//
//	if(_words == 0) {return 0;}
//
//	while(allWords < _words)
//	{
//		ret = getEvent(_data+allWords, _eventCounter_old, &words, words_icescint_9);
//		if(ret == 0){okEvents++;}
//		else{errorEvents +=ret;}
//		allWords += words;
//	}
//
//	*_okEvents = okEvents;
//	*_errorEvents = errorEvents;
//	return 0;
//}

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

int main(int argc, char** argv)
{
	timeval time_old;
	timeval time_new;
	std::string server;
	int port;
	int error = 0;
	int okCounter = 0;
	int errorCounter = 0;
	int okEvents = 0;
	int errorEvents = 0;
	long delta_us = 0;
	double rate = 0;
	uint32_t eventCounter = 0;
	int newFileTimeout = 0;
	int newFileTime = 0;
	std::string newFilePath;
	int writeFile = 0;
	int createDoneFile = 0;
	int fifoWidthWords = 9;

	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
//			("verbose,v", "be verbose")
			("server", po::value<std::string>(&server)->default_value("127.0.0.1"), "server data is send to")
			("port", po::value<int>(&port)->default_value(10011), "server port data is send to")
			("newFileTimeout,f", po::value<int>(&newFileTimeout)->default_value(-1), "new file will be created after [sec]")
			("newFileTime,m", po::value<int>(&newFileTime)->default_value(-1), "new file will be created after [sec] from UTC midnight")
			("newFilePath,p", po::value<std::string>(&newFilePath)->default_value("/tmp/"), "new file will be created here")
			("writeFile,w", "write to file if true")
			("createDoneFile,d", "create a *.done file")
			("printRawData,r", "print the raw data as hex to std::out")
			("printRawDataDec,R", "print the raw data as dec to std::out")
			("fifoWidthWords,l", po::value<int>(&fifoWidthWords)->default_value(9), "number of words per line")
			("printDebugData,b", "print debug data to std::out")
//			("validate", "validate data")
			("verbose,v", po::value<int>(&verbose)->default_value(0) ,"verbose level")
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
		std::cout << "description: runs tests with the test generator to test irq, fifo and network sending" << std::endl << desc << std::endl;
		return 1;
	}

//	if (vm.count("verbose")) {verbose = 1;}
	if (vm.count("createDoneFile")) {createDoneFile = 1;}

	writeFile = vm.count("writeFile");

	zmq::context_t context(1);
	zmq::socket_t subscriber(context, ZMQ_SUB);
	std::ostringstream connectAddress;
	connectAddress << "tcp://" << server << ":" << port;

	if (verbose) std::cout << "connecting to " << connectAddress.str() << std::endl;

	subscriber.connect(connectAddress.str().c_str());
	// set 0 filter, receiver everything!
	subscriber.setsockopt( ZMQ_SUBSCRIBE, "", 0);

	uint64_t numMessages = 0;

	time_t rawtime_now = 0;
	time_t rawtime_old = 0;
	time_t rawtime_end = 0;
	struct tm timeinfo_now;
	int seconds;
	int result;

	std::ofstream myfile;
	std::string currentFileName;

	rawtime_old = time(NULL);
	rawtime_now = time(NULL);

	gettimeofday(&time_old,NULL);
	gettimeofday(&time_new,NULL);

	if(writeFile)
	{
		currentFileName = getPath(rawtime_now, newFilePath);
		myfile.open (currentFileName.c_str(), std::ios::out | std::ios::app | std::ios::binary);
		std::cout << "writing to file " << currentFileName << "..." << std::endl;
	}

	if(newFileTime > -1)
	{
		rawtime_end = getNextDayTime(newFileTime,rawtime_now);
		std::cout << "file will end at " << getTimeString(rawtime_end) << std::endl;
	}

	zmq::message_t message;

//	TestDataValidator validator;

	while (1)
	{
		if (subscriber.recv(&message))
		{
			numMessages++;
//			if ((numMessages % 1000) == 0) {std::cout << numMessages << std::endl;}
			if (verbose) {std::cout << numMessages << std::endl;}

//			readAndValidateEventsDirect((uint16_t*) message.data(), message.size() / 2, &eventCounter, &okEvents, &errorEvents);

//			if(vm.count("validate")) {
//				validator.process(message.data(), message.size());
//			}

			if(vm.count("printRawData"))
			{
				std::cout << "->  " << std::endl;
				readAndPrintEventsDirect((uint16_t*) message.data(), message.size() / 2, fifoWidthWords, 0);
			}
			if(vm.count("printRawDataDec"))
			{
				std::cout << "->  " << std::endl;
				readAndPrintEventsDirect((uint16_t*) message.data(), message.size() / 2, fifoWidthWords, 1);
			}

			if(writeFile)
			{
				myfile.write((char*)message.data(), message.size());

				rawtime_now = time(NULL);
				seconds = difftime(rawtime_now, rawtime_old);

//				if(seconds >= newFileTimeout)
//				{
//					myfile.close();
//					currentFileName = getPath(rawtime_now, newFilePath);
//					myfile.open(currentFileName.c_str(), std::ios::out | std::ios::app | std::ios::binary);
//					std::cout << "creating new file " << getPath(rawtime_now, newFilePath) << std::endl;//", will be renamed to " << currentFileName.replace(currentFileName.end()-3,currentFileName.end(),"bin") << std::endl;
//					rawtime_old = rawtime_now;
//				}
				if(((newFileTime > -1) && (rawtime_now > rawtime_end)) || ((seconds >= newFileTimeout) && (newFileTimeout > 0)))
				{
					rawtime_end = rawtime_end + oneDay;

					myfile.close();
					std::cout << "finished writing" << currentFileName << std::endl;

					if(createDoneFile)
					{
						currentFileName.replace(currentFileName.end()-3,currentFileName.end(),"done").c_str();
						myfile.open(currentFileName.c_str(), std::ios::out | std::ios::app | std::ios::binary);
						myfile.close();
					}

					currentFileName = getPath(rawtime_now, newFilePath);
					myfile.open(currentFileName.c_str(), std::ios::out | std::ios::app | std::ios::binary);
					std::cout << "writing to file " << currentFileName << "..." << std::endl;

					if((seconds >= newFileTimeout) && (newFileTimeout > 0))
					{
						rawtime_old = rawtime_now;
					}
				}
			}

			if(vm.count("printDebugData"))
			{
				okCounter += okEvents;
				errorCounter += errorEvents;

				gettimeofday(&time_new,NULL);
				delta_us  = (time_new.tv_sec-time_old.tv_sec)*1000000 + (time_new.tv_usec-time_old.tv_usec);

				if(delta_us > (10 * 1000000)) // 10 sec
				{
					rate = (okCounter*1000000.0)/delta_us;
					std::cout << "delta: " << std::dec << delta_us << " , events: " << okCounter << " ok / " << errorCounter << " errors, rate: " << rate << " Hz == " << 1000000000.0/rate << "ns" << std::endl;
					okCounter = 0;
					errorCounter = 0;
					gettimeofday(&time_old,NULL);
				}
			}
		}

	}
	if(writeFile)
	{
		myfile.close();
	}
	context.close();

	return 0;
}
