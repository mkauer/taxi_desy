/*
 * drs4_waveform.hpp
 *
 *  Created on: Jul 26, 2017
 *      Author: marekp
 */

#ifndef TAXI_ICESCINT_TEST_ROOT_DRS4_WAVEFORM_HPP_
#define TAXI_ICESCINT_TEST_ROOT_DRS4_WAVEFORM_HPP_

#include <iostream>
#include <fstream>
#include <vector>

class drs4_waveform_t {
public:
	Int_t roi;
	Short_t samples[8][1024];
	UInt_t sampleCount;
} ;

// find correlation of two waveforms of same channel with a given shift
int correlate_diff(drs4_waveform_t& w1, drs4_waveform_t& w2, int _channel, int _shift)
{
	int sum=0;
	for (int i=0;i<w1.sampleCount;i++) {
		size_t pos1=i;
		int pos2=(_shift+i);
		if (pos2>=w2.sampleCount) pos2-=w2.sampleCount;
		int diff=w1.samples[_channel][pos1] - w2.samples[_channel][pos2];
		if (diff<0) diff=-diff;
		sum+=diff;
	}
	return sum;
}

// find correlation of two waveforms of same channel with a given shift
void differentiate(drs4_waveform_t& w1)
{
	drs4_waveform_t wcopy=w1;
	for (int i=0;i<w1.sampleCount;i++) {
		int nextPos=i+1;
		if (nextPos==w1.sampleCount) nextPos=0;
		for (int j=0;j<8;j++) {
			w1.samples[j][i]=wcopy.samples[j][nextPos]-wcopy.samples[j][i];
		}
	}
}

// find correlation of two waveforms of same channel with a given shift
int64_t correlate_mul(drs4_waveform_t& w1, drs4_waveform_t& w2, int _channel, int _shift)
{
	int64_t sum=0;
	for (int i=0;i<w1.sampleCount;i++) {
		size_t pos1=i;
		int pos2=(_shift+i);
		if (pos2>=w2.sampleCount) pos2-=w2.sampleCount;
//		size_t pos2=(i+_shift) % w2.sampleCount;
		int mul=w1.samples[_channel][pos1] * w2.samples[_channel][pos2];
//		if (diff<0) diff=-diff;
		sum+=mul;
	}
	return sum;
}

// function to read waveforms from a file
bool drs4_readWaveforms(const std::string& _fileName, std::vector<drs4_waveform_t>& waveforms, int _maxCount=-1)
{
	using namespace std;

	ifstream is;
	is.open (_fileName.c_str(), ios::binary );

	if (!is.is_open()) {
		std::cerr << "could not open file!" << std::endl;
		return false;
	}

	int roi;
	int sampleCount=0;

	unsigned short buffer[9];
	memset(buffer,0,sizeof(buffer));

	bool first=true;
	drs4_waveform_t w;
	memset(&w,0,sizeof(w));

	while (!is.eof()) {
		// read data as a block of 18bytes
		is.read ((char*)buffer, sizeof(buffer));

		if ((buffer[0] & 0xF000) == 0x1000) {
			if (w.sampleCount>0) waveforms.push_back(w);

			roi = buffer[8];
			memset(&w,0,sizeof(w));
			w.roi=roi;
			w.sampleCount=0;

			first=false;
			if ((_maxCount>=0) && (waveforms.size()>=_maxCount)) break;
		} else if ((buffer[0] & 0xF000) == 0x4000) {
			for (int j=0;j<8;j++) {
				if (w.sampleCount<1024) {
					w.samples[j][w.sampleCount]=buffer[j+1];
				} // else throw away data
			}
			w.sampleCount++;
		} else {
			cout << "unknown header " << std::hex << buffer[0] << " "<< std::endl ;
		}
	}

	return true;
}

#endif /* TAXI_ICESCINT_TEST_ROOT_DRS4_WAVEFORM_HPP_ */
