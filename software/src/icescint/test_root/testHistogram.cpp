/*
 * test.cpp
 *
 *  Created on: Jul 20, 2017
 *      Author: marekp
 */

#include <iostream>
#include <fstream>
#include "TObject.h"
#include "TString.h"
#include "TObjArray.h"
#include "TFile.h"
#include "TROOT.h"
#include "TH1.h"

int main(int argc, char** argv)
{
	char name[10], title[20];
	unsigned short buffer[9];
	memset(buffer,0,sizeof(buffer));


	TObjArray Hlist(0);      // create an array of Histograms
	TH1F* h[9];                 // create a pointer to a histogram
	// make and fill 15 histograms and add them to the object array
	for (Int_t i = 0; i < 8; i++) {
	  sprintf(name,"h%d",i);
	  sprintf(title,"histo nr:%d",i);
	  h[i] = new TH1F(name,title,1000,0,1 << 14);
	  Hlist.Add(h[i]);
	}
	h[8] = new TH1F("h8","rois",1024,0,1024);
	Hlist.Add(h[8]);


	using namespace std;

	ifstream is;
	is.open (argv[1], ios::binary );

	if (!is.is_open()) {
		std::cerr << "could not open file!" << std::endl;
		return 0;
	}

	int roi;

	while (!is.eof()) {
		// read data as a block:
		is.read ((char*)buffer, sizeof(buffer));

		/*
		for (int i=0;i<9;i++) {
			cout << std::hex << buffer[i] << " " ;
		}
		cout << std::endl;*/

		if ((buffer[0] & 0xF000) == 0x1000) {
			roi = buffer[8];
			h[8]->Fill(roi);
		} else if ((buffer[0] & 0xF000) == 0x4000) {
			for (int j=0;j<8;j++) {
				h[j]->Fill(buffer[j+1] & 0x1fff);
			}
		} else {
			cout << "unknown header " << std::hex << buffer[0] << " "<< std::endl ;
		}
	}

	// open a file and write the array to the file
	TFile f("test.root","recreate");
	Hlist.Write();
	f.Close();
}
