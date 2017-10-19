/*
 * test.cpp
 *
 *  Created on: Jul 20, 2017
 *      Author: marekp
 */

#include <stdint.h>
#include <iostream>
#include <fstream>
#include "TObject.h"
#include "TString.h"
#include "TObjArray.h"
#include "TFile.h"
#include "TTree.h"
#include "TROOT.h"
#include "TH1.h"
#include "TH2.h"
#include "TCanvas.h"
#include "TGraph.h"
#include <algorithm>
#include <map>

#include "drs4_waveform.hpp"

/*
typedef struct {
	int sum;
	int shift;
} corr_result_t;

// find best correlation of two waveforms of same channel with a given shift
void bestCorrelatDiffeMin(waveform_t& w1, waveform_t& w2, int _channel, corr_result_t& _best,  std::vector<corr_result_t>& _stack)
{
	corr_result_t best;
	std::vector<corr_result_t> stack;
	for (int i=0;i<w1.sampleCount;i++) {
		int sum=correlate(w1,w2,_channel,i+1);
		if (i==0) {
			best.sum=sum;
			best.shift=i;
			stack.insert(stack.begin(),best);
		} else if (best.sum>sum) {
			best.sum=sum;
			best.shift=i;
			stack.insert(stack.begin(),best);
		}
	}
	_best=best;
	_stack=stack;
}

// find best correlation of two waveforms of same channel with a given shift
void bestCorrelateMax(waveform_t& w1, waveform_t& w2, int _channel, corr_result_t& _best,  std::vector<corr_result_t>& _stack)
{
	corr_result_t best;
	std::vector<corr_result_t> stack;
	for (int i=0;i<w1.sampleCount;i++) {
		int sum=correlate(w1,w2,_channel,i+1);
		if (i==0) {
			best.sum=sum;
			best.shift=i;
			stack.insert(stack.begin(),best);
		} else if (best.sum<=sum) {
			best.sum=sum;
			best.shift=i;
			stack.insert(stack.begin(),best);
		}
	}
	_best=best;
	_stack=stack;
}

*/
int min(int a,int b)
{
	if (a<b) return a; else return b;
}

// finds the key,value pair where value is max, returns number of occurences
int getdMaxValuesInMap(std::map<int,int> _map, int& _key, int& _value)
{
	typedef std::map<int,int>::iterator iterator;

	int count=0;
	int key;
	int val;

	for (iterator it=_map.begin();it!=_map.end();++it) {
		if (it==_map.begin()) {
			count=1;
			key=it->first;
			val=it->second;
		} else {
			if (val<it->second) {
				count=1;
				key=it->first;
				val=it->second;
			} else if (val==it->second) {
				count++;
			}
		}
	}

	_key=key;
	_value=val;

	return count;
}


int main()
{
	char name[10], title[20];

	//char fileName[]="/var/oe/taxi/user/marekp/workspace/camera_software_x86_Debug/taxi/icescint/test_root/eventData_1500567977_2017-07-20_18-26-17.bin";
	char fileName[]="/var/oe/taxi/user/marekp/workspace/camera_software_x86_Debug/taxi/eventReceiver/eventData_1500973474_2017-07-25_11-04-34.bin";

	Float_t waveforms[8][1024];

	TFile *file=new TFile("waveforms.root","RECREATE");
	TTree *tree=new TTree("tree","Testing still");
	tree->Branch("waveforms",waveforms,"waveforms[8][1024]/F");

	using namespace std;

	int roi;
	int sampleCount=0;

	std::vector<drs4_waveform_t> w;

	if (!drs4_readWaveforms(fileName, w, 10000)) {
		std::cerr << "could not read waveforms from file!" << std::endl;
		return 0;
	}

	std::cout << "have read " << w.size() << std::endl;

	for(Int_t i=0;i<w.size();i++) {
		std::cout << "process waveform " << i << std::endl;
		for(Int_t n=0;n<8;n++) {
			for(Int_t k=0;k<1023;k++) {
				waveforms[n][k]=w[i].samples[n][k];
			}
		}
		tree->Fill();
	}
	tree->Write();
	file->Flush();
	// open a file and write the array to the file
	file->Close();
}
