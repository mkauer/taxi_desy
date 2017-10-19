/*
 * icescint_validator.hpp
 *
 *  Created on: Jul 18, 2017
 *      Author: marekp
 */

#ifndef SOURCE_DIRECTORY__TAXI_DRIVER_TEST_DAQDRV_ICESCINT_VALIDATOR_HPP_
#define SOURCE_DIRECTORY__TAXI_DRIVER_TEST_DAQDRV_ICESCINT_VALIDATOR_HPP_

extern int verbose;

typedef struct {
	uint16_t type; 			// should be 0xb000
	uint32_t eventCounter;
	uint16_t eventLength; 	// number of events including header
	uint16_t reserved[5];
} taxi_testdata_header_t;

typedef struct {
	uint16_t type; 			// should be 0xcXXX
	uint16_t data[8];
} taxi_testdata_sample_t;



class TestDataDecoder
{
public:
	typedef enum {
		WAIT_HEADER,
		PROCESS_HEADER_B000,
		PROCESS_HEADER_CXXX,
	} state_t;

	typedef enum {
		NONE,
		HEADER_B000,
		HEADER_CXXX,
	} decoder_type_t;


	state_t state;
	int dataWordCount;

	int  lastData[9];
	taxi_testdata_header_t header;
	taxi_testdata_sample_t data;


	TestDataDecoder()
	{
		state=WAIT_HEADER;
		for (int i=0;i<9;i++) lastData[i]=-1;
	}

	// returns true, if a known packet was detected
	decoder_type_t processData(uint16_t _data)
	{
		for (int i=0;i<8;i++) lastData[i]=lastData[i+1];
		lastData[8]=_data;

		if (state==WAIT_HEADER) {
			if (_data==0xb000) {
				// found header!
				state=PROCESS_HEADER_B000;
				dataWordCount=0;
				header.type=_data;
			} else if ((_data & 0xF000)==0xc000) {
				// found 0xcXXX header!
				state=PROCESS_HEADER_CXXX;
				dataWordCount=0;
				data.type=_data;
			} else {
				std::cerr << "expected b000 or cxxx but got 0x" << std::hex << _data << std::endl;
			}
		} else if (state==PROCESS_HEADER_B000) {
			switch (dataWordCount)
			{
			case 0: {
				header.eventCounter=_data << 16;
				break;
			}
			case 1: {
				header.eventCounter|=_data;
				break;
			}
			case 2: {
				header.eventLength=_data;
				break;
			}
			case 3:
			case 4:
			case 5:
			case 6: {
				header.reserved[dataWordCount-3]=_data;
				break;
			}
			case 7: {
				header.reserved[dataWordCount-3]=_data;
				state=WAIT_HEADER;
				return HEADER_B000;
			}
			default:
				break;
			}
			dataWordCount++;
		} else if (state==PROCESS_HEADER_CXXX) {
			data.data[dataWordCount] = _data;
			if (dataWordCount==7) {
				state=WAIT_HEADER;
				return HEADER_CXXX;
			}
			dataWordCount++;
		}
		return NONE;
	}

};


class TestDataValidator
{
public:

	bool hasLastHeader;
	taxi_testdata_header_t lastHeader;
	bool hasLastSample;
	taxi_testdata_sample_t lastSample;

	int eventSampleCounter;

	TestDataDecoder decoder;

	TestDataValidator()
	{
		hasLastHeader=false;
	}

	void process(taxi_testdata_header_t _header)
	{
		if (hasLastHeader) {
			if ((lastHeader.eventCounter+1) != _header.eventCounter) {
				std::cerr << "header: eventcounter mismatch, expected " << std::dec << (lastHeader.eventCounter+1) << " but got " << _header.eventCounter << std::endl;
			}
		}
		eventSampleCounter=0;
		lastHeader=_header;
		hasLastSample=false;
	}

	void process(taxi_testdata_sample_t _sample)
	{
		uint16_t expectedSample=0;

		if (hasLastSample) {
			uint16_t expected=(lastSample.type & 0x3ff)+1;
			if ( expected!= (_sample.type & 0x3ff)) {
				std::cerr << "header: Cxxx header mismatch, expected " << std::dec << expected << " but got " << (_sample.type & 0x3ff) << std::endl;
			}
			expectedSample=lastSample.data[7]+1;
		}

		for (int i=0;i<8;i++) {
			if (_sample.data[i]!=expectedSample) {
				std::cerr << "testdata mismatch: expected " << std::dec << expectedSample << " but got " << _sample.data[i] << std::endl;
			}
			expectedSample=_sample.data[i]+1;
		}

		lastSample=_sample;
		hasLastSample=true;
	}

	void process(void* _data, size_t _size)
	{
		if (_size==0) return;

		int countSamples=0;

		for(int i=0;i<_size/2;i++) {
			int dum=((uint16_t*)_data)[i];
			TestDataDecoder::decoder_type_t t=decoder.processData(dum);
			if (t==TestDataDecoder::NONE) {

			} else if (t==TestDataDecoder::HEADER_B000) {
				if (verbose) std::cout << "got B000 header: ec:" << std::dec << decoder.header.eventCounter << " len:" << std::dec << decoder.header.eventLength << std::endl;
				process(decoder.header);
				countSamples++;
			} else if (t==TestDataDecoder::HEADER_CXXX) {
				process(decoder.data);
				countSamples++;
				//std::cout << "got CXXX header: #:" << std::dec << (decoder.data.type & 0x3ff) << std::endl;
			}

			if (verbose>1) {
				if (t!=TestDataDecoder::NONE) {
					for(int i=0;i<9;i++) {
						std::cout << "" <<  std::setfill('0') << std::setw(4) << std::hex << decoder.lastData[i] << " ";
					}
					std::cout << " - ";
					countSamples++;
					if (countSamples % 2 ==1) std::cout << std::endl;
				}
			}
		}
	}
};




#endif /* SOURCE_DIRECTORY__TAXI_DRIVER_TEST_DAQDRV_ICESCINT_VALIDATOR_HPP_ */
