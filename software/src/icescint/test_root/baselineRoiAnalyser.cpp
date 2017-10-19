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
#include <algorithm>
#include <map>

#include <boost/asio/io_service.hpp>
#include <boost/bind.hpp>

#include <boost/thread.hpp>
#include "boost/thread/thread.hpp"
#include <boost/program_options.hpp>

#include "drs4_waveform.hpp"

typedef struct {
	int64_t sum;
	int shift;
} corr_result_t;

struct corr_compare
{
    inline bool operator() (const corr_result_t& a, const corr_result_t& b)
    {
        return (a.sum > b.sum);
    }
};

// find best correlation of two waveforms of same channel with a given shift
void bestCorrelatDiffMin(drs4_waveform_t& w1, drs4_waveform_t& w2, int _channel, corr_result_t& _best,  std::vector<corr_result_t>& _stack)
{
	corr_result_t best;
	std::vector<corr_result_t> stack;
	for (int i=0;i<w1.sampleCount;i++) {
		int sum=correlate_diff(w1,w2,_channel,i+1);
		best.sum=sum;
		best.shift=i;
		stack.insert(stack.begin(),best);
/*		if (i==0) {
			best.sum=sum;
			best.shift=i;
		} else if (best.sum>sum) {
			best.sum=sum;
			best.shift=i;
			stack.insert(stack.begin(),best);
		}*/
	}
	std::sort(stack.begin(),stack.end(),corr_compare());
	_best=stack[0];
	_stack=stack;
}

// find best correlation of two waveforms of same channel with a given shift
void bestCorrelateMax(drs4_waveform_t& w1, drs4_waveform_t& w2, int _channel, corr_result_t& _best,  std::vector<corr_result_t>& _stack)
{
	corr_result_t best;
	std::vector<corr_result_t> stack;
	for (int i=0;i<w1.sampleCount;i++) {
		int64_t sum=correlate_mul(w1,w2,_channel,i);
		best.sum=sum;
		best.shift=i;
		stack.insert(stack.begin(),best);
	}
	std::sort(stack.begin(),stack.end(),corr_compare());
	_best=stack[0];
	_stack=stack;
}

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

class Result{
public:
	typedef boost::recursive_mutex MUTEX;
	typedef boost::lock_guard<MUTEX> LOCK_GUARD;

	mutable MUTEX m_mutex;

	int count;

	//TH2* roiDiffShiftDiffHist1024;
	TH2* roiDiffShiftMulHist1024[8];
	TH1F* roiShiftHistAll[1024];                 // create a pointer to a histogram
	TH1F* dataHist[8];                 // create a pointer to a histogram

	Result(TObjArray& _Hlist)
	{
		count=0;
		char name[80];
		char title[80];
//		roiDiffShiftDiffHist1024=new TH2F("roidiff_shift_diff","roidiff vs shift diff-corr",1024,0,1023,1024,0,1023);
//		_Hlist.Add(roiDiffShiftDiffHist1024);


		for (Int_t i = 1; i < 8; i++) {
			sprintf(name,"roidiff_shift_mul_t%d",i);
			sprintf(title,"roidiff vs shift mul-corr th=%d",i);
			roiDiffShiftMulHist1024[i]=new TH2F(name,title,1024,0,1023,1024,0,1023);
			_Hlist.Add(roiDiffShiftMulHist1024[i]);
		}

		for (Int_t i = 0; i < 8; i++) {
		  sprintf(name,"datahist_%d",i);
		  sprintf(title,"data value histogram of channel %d",i);
		  dataHist[i] = new TH1F(name,title,1024,0,14000);
		  _Hlist.Add(dataHist[i]);
		}

		for (Int_t i = 0; i < 1024; i++) {
		  sprintf(name,"roishift_%d",i);
		  sprintf(title,"roi shift = %d , th=7",i);
			roiShiftHistAll[i] = new TH1F(name,title,1024,0,1023);
			_Hlist.Add(roiShiftHistAll[i]);
		}
	}

	void countUp()
	{
		LOCK_GUARD lock(m_mutex);
		count++;
	}

	void FillMulCorr(Float_t roiDiff, int shiftMul, int threshold)
	{
		if ((threshold<0) || (threshold>=8)) return;
		LOCK_GUARD lock(m_mutex);

		roiDiffShiftMulHist1024[threshold]->Fill(roiDiff,shiftMul);
		if (threshold==7) {
			roiShiftHistAll[shiftMul]->Fill(roiDiff);
		}
	}

/*	void FillDiffCorr(Float_t roiDiff, Float_t shiftDiff)
	{
		LOCK_GUARD lock(m_mutex);
		roiDiffShiftDiffHist1024->Fill(roiDiff,shiftDiff);
	}
*/

	void FillData(int channel, Float_t data)
	{
		if ((channel<0) || (channel>=8)) return;
		LOCK_GUARD lock(m_mutex);
		dataHist[channel]->Fill(data);
	}

};

// threadable job
void doCorrelationJob(std::vector<drs4_waveform_t>& waveforms, int _start, Result& _result)
{
	drs4_waveform_t& w1=waveforms[_start];

	// create data histograms
	for (int j=0;j<w1.sampleCount;j++) {
		for (int c=0;c<8;c++) _result.FillData(c,w1.samples[c][j]);
	}

	for (int j=(_start+1);j<waveforms.size();j++) {
		_result.countUp();

		drs4_waveform_t& w2=waveforms[j];

		std::map<int,int> shiftMap;

		int roiDiff=w2.roi-w1.roi;
		if (roiDiff<0) roiDiff+=1024;

		// mul corr go through all channels
		for (int t=0;t<7;t++) {
			corr_result_t best;
			std::vector<corr_result_t> stack;
			bestCorrelateMax(w1, w2, t, best, stack);
			size_t c=min(8, stack.size());

			for (int r=0;r<c;r++) {
				int thresh=shiftMap[stack[r].shift]+1;
				shiftMap[stack[r].shift]=thresh;
				_result.FillMulCorr(roiDiff, stack[r].shift, thresh );
			}
		}
	}
}

int main(int argc, char** argv)
{
	boost::asio::io_service ioService;
	boost::thread_group threadpool;

	boost::asio::io_service::work work(ioService);

	std::string filename;
	std::string filenameOut;
	int waveformCount;
	int threadCount;

	using namespace std;
	namespace po = boost::program_options;

	po::options_description desc("Allowed options");
	desc.add_options()
		("help,h", "")
		("file,f", po::value<std::string>(&filename), "binary input data filename")
		("outputFile,o", po::value<std::string>(&filenameOut)->default_value("output.root"), "output root-file for result")
		("waveformCount,c", po::value<int>(&waveformCount)->default_value(50), "number of waveforms to progress")
		("threads", po::value<int>(&threadCount)->default_value(10), "number of threads to use")
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
		std::cout << "tool to validate the roi via cross correlation or the baseline" << std::endl << desc << std::endl;
		return 1;
	}

	if (!vm.count("file"))
	{
		std::cout << "need to specifiy an input file with -f" << std::endl << desc << std::endl;
		return 1;
	}

	std::vector<drs4_waveform_t> waveforms;
	if (!drs4_readWaveforms(filename.c_str(),waveforms, waveformCount))
	{
		std::cerr << "error loading file '" << filename << "'" << std::endl << desc << std::endl;
		return 1;
	}

	/*
	 * This will add n threads to the thread pool.
	 */
	for (int i=0;i<threadCount;i++) {
		threadpool.create_thread(
			boost::bind(&boost::asio::io_service::run, &ioService)
		);
	}

	TObjArray Hlist(0);      // create an array of Histograms
	Result result(Hlist);

	float progress;
	int count=0;
	int roiShift=0;

	int totalCorrelations=waveforms.size()*(waveforms.size()+1)/2;

	std::cout << "start processing " << waveforms.size() << " waveforms -> " << (totalCorrelations*7) << " cross correlations"<<  std::endl;

	// start all the jobs
	for (int i=0;i<waveforms.size();i++) {
		ioService.post(boost::bind(doCorrelationJob, boost::ref(waveforms), i, boost::ref(result)));
	}

	/*
	 * This will stop the ioService processing loop. Any tasks
	 * you add behind this point will not execute.
	*/

	int polls;
	do {
		polls=ioService.poll_one();

		float progress=result.count*100/totalCorrelations;
		std::cout << "process " << progress << "%" <<  std::endl;

		sleep(1);
	} while (polls!=0);

	std::cout << "done" <<  std::endl;

	ioService.stop();

	/*
	 * Will wait till all the threads in the thread pool are finished with
	 * their assigned tasks and 'join' them. Just assume the threads inside
	 * the threadpool will be destroyed by this method.
	 */
	threadpool.join_all();

	// open a file and write the array to the file
	TFile f(filenameOut.c_str(),"recreate");
	Hlist.Write();
	f.Close();

}
