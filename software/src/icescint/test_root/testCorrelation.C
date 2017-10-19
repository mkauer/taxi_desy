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
#include "TMultiGraph.h"
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


typedef struct {
	Float_t corr[1024];
	Float_t values1[1024];
	Float_t values2[1024];
} w_t;

int testCorrelation()
{
	char name[10], title[20];

	char fileName[]="/var/oe/taxi/user/marekp/workspace/camera_software_x86_Debug/taxi/eventReceiver/eventData_1500973474_2017-07-25_11-04-34.bin";

	Float_t xcorr[1024];

	Float_t corrMul[1024];
	Float_t corrDiff[1024];

	w_t graphs[100];
	TFile *file=new TFile("testCorr.root","RECREATE");
	TTree *tree=new TTree("tree","Testing still");
	tree->Branch("corrMul",corrMul,"corrMul[1024]/F");
	tree->Branch("corrDiff",corrDiff,"corrDiff[1024]/F");

	using namespace std;


	int roi;
	int sampleCount=0;

	std::vector<drs4_waveform_t> waveforms;

	if (!drs4_readWaveforms(fileName, waveforms, 5)) {
		std::cerr << "could not read waveforms from file!" << std::endl;
		return 0;
	}

	for(Int_t j=0;j<1024;j++) {
		xcorr[j]=j;
	}

    TCanvas *c1 = new TCanvas(name,"MUL correlation",200,10,700,500);
    c1->cd(0);
    TMultiGraph *mg1 = new TMultiGraph("c1","ttt");

	for(Int_t i=1;i<waveforms.size();i++) {

		drs4_waveform_t& w0=waveforms[i-1];
		drs4_waveform_t& w1=waveforms[i];

		//	differentiate(w1);
		//	differentiate(w0);

		std::cerr << "processing waveforms " << i << " " << w0.sampleCount << "," << w0.roi << "  " << w1.sampleCount << "," << w1.roi << std::endl;
		for(Int_t j=0;j<1024;j++) {
		//	std::cout << i << " " << i << " " << w1.samples[1][j] << std::endl;
			graphs[i].corr[j]=correlate_diff(w0,w1,1,j);
			graphs[i].values1[j]=w0.samples[1][j]+1000*i;
			graphs[i].values2[j]=w1.samples[1][j];
			//corrDiff[j]=correlate_diff(w0,w1,0,j);
		}


		char name[10];
		sprintf(name,"c%d",i);

	    /*TGraph* gr1 = new TGraph(1024,xcorr,graphs[i].values1);
	    mg1->Add(gr1);
	    TGraph* gr3 = new TGraph(1024,xcorr,graphs[i].values2);
	    mg1->Add(gr3);
	    */
	    TGraph* gr2 = new TGraph(1024,xcorr,graphs[i].corr);
	    mg1->Add(gr2);
	    //TGraph* gr = new TGraph(1024,xcorr,graphs[i].values);
	}

    mg1->Draw("AL");
    //mg2->Draw("AL");


}
