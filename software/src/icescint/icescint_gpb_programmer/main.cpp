#include "boost/date_time/posix_time/posix_time.hpp"
#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>

#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <iostream>
#include <sstream>
#include "hexfile.h"
#include <fstream>

#include "FlashMemory.hpp"

#include "gpb/USBSerialTransport.hpp"

#include "gpb/TaxiSerialTransport.hpp"

#include "gpb/GPBPacketProtocol.hpp"

#define  error_message(MSG...) (MSG)

char portname[] = "/dev/ttyUSB0";

class GPBProgrammer {
private:
	enum{
		TIMEOUT = 1000
	};

	GPBPacketProtocol* 	m_protocol;
	gpb_packet_t 		m_packet;
	unsigned char 		m_packet_data[1000];

	int prepare_readCmd(gpb_packet_t* _packet, unsigned short _addr, unsigned short _length)
	{
		if (_packet->data_size<4) return 0; // error, packet does not fit
		_packet->size=4;
		_packet->type=3;

		gpb_packet_write_u16(_packet, 0, _addr);
		gpb_packet_write_u16(_packet, 2, _length);

		return 4;
	}

	int prepare_startCmd(gpb_packet_t* _packet)
	{
		_packet->size=0;
		_packet->type=5;
		return 0;
	}

	int prepare_writeCmd(gpb_packet_t* _packet, unsigned short _addr, void* _data, unsigned short _length)
	{
		size_t s=_length+2;
		if (_packet->data_size<s) return 0; // error, packet does not fit
		_packet->size=s;
		_packet->type=2;

		gpb_packet_write_u16(_packet, 0, _addr);

		unsigned char* p=reinterpret_cast<unsigned char*>(_data);
		for (int i=0;i<_length;i++) {
			gpb_packet_write(_packet, i+2, p[i]);
		}

		return s;
	}
public:

	GPBProgrammer(GPBPacketProtocol* _protocol)
	: m_protocol(_protocol)
	{
		gpb_packet_init(&m_packet, 0, m_packet_data, sizeof(m_packet_data));
	}

	bool verifyFlash(std::string _filename)
	{
		using namespace std;
		gpb_packet_t packet;
		unsigned char packet_data[1000];
		gpb_packet_init(&packet, 0, packet_data, sizeof(packet_data));

		ifstream infile(_filename.c_str());

		std::string line;
		int line_n=0;
		while (std::getline(infile, line))
		{
			hex_data_t hexdata;
			if (!processHexFileLine(line, hexdata)) {
				cerr << "error processing hex file line " << line_n << endl;
				break;
			}

			unsigned char c=hexdata.checksum - hexdata.checksum_computed;

			if (c!=0) {
				cerr << "checksum error processing hex file line " << line_n << endl;
				break;
			}

			std::cout << "verify addr: 0x" << std::hex << hexdata.addr << " size: " << dec << hexdata.length << std::endl;

			while(1) {
				usleep(10000);
				// Send
	//			std::cout << "send packet" << std::endl;
				gpb_packet_init(&packet, 0, packet_data, sizeof(packet_data));
				prepare_readCmd(&packet, hexdata.addr, hexdata.length);
				m_protocol->sendPacket(&packet);
				int error=m_protocol->receivePacket(2000);

				if (error<0) {
					std::cout << "programmer protocol error: " << error << std::endl;
					return false;
				}

				if (error==0) {
					std::cout << "programmer timeout error, resend packet " << std::endl;
					continue;
				}

				break;
			} ;

	//		std::cout << "packet successfull received" << std::endl;

			const gpb_packet_t& rpacket=m_protocol->receivedPacket();

			for (int i=0;i<rpacket.size;i++) {

				if (hexdata.data[i]!=rpacket.data[i]) {
					std::cout << std::endl << "verify FAILED! pos:" << i << " " << (((unsigned int)rpacket.data[i])&0xff) << " != " << (((unsigned int)hexdata.data[i])&0xff) << std::endl;

					cout << "hex line: " << line_n << " type: " << dec << hexdata.type << " addr: 0x" << hex << hexdata.addr << " bytes " << dec << hexdata.length << " checksum: " << ((int)c) << endl;

	//				std::cout << std::hex << " 0x" << (((unsigned int)packet.data[i])&0xff);

					std::cout << "flash  : ";
					for (int i=0;i<rpacket.size;i++) {
						std::cout << std::hex << " 0x" << (((unsigned int)rpacket.data[i])&0xff);
					}
					std::cout << endl;
					std::cout << "hexfile: ";
					for (int i=0;i<hexdata.length;i++) {
						std::cout << std::hex << " 0x" << (((unsigned int)hexdata.data[i])&0xff);
					}
					std::cout << endl;

		//			return false;
				}
			}


			line_n++;
		    // process pair (a,b)
		}

		return true;
	}

	bool testWriteFlash()
	{
		gpb_packet_t packet;
		unsigned char packet_data[1000];

		gpb_packet_init(&packet, 0, packet_data, sizeof(packet_data));

		unsigned char buf[64];
		for (int i=0;i<sizeof(buf);i++) buf[i]=i;

		std::cout << "send packet test write packet" << std::endl;
		gpb_packet_init(&packet, 0, packet_data, sizeof(packet_data));
		prepare_writeCmd(&packet, 0xf000, buf, sizeof(buf));
		m_protocol->sendPacket(&packet);
	}

	bool writeFlash(std::string _filename)
	{
		gpb_packet_t packet;
		unsigned char packet_data[1000];
		gpb_packet_init(&packet, 0, packet_data, sizeof(packet_data));

		FlashMemory memory;

		using namespace std;

		ifstream infile(_filename.c_str());

		std::string line;
		int line_n=0;
		while (std::getline(infile, line))
		{
			hex_data_t hexdata;

	//		std::cout <<  line << std::endl;

			if (!processHexFileLine(line, hexdata)) {
				cerr << "error processing hex file line " << line_n << endl;
				break;
			}

			unsigned char c=hexdata.checksum - hexdata.checksum_computed;

			if (c!=0) {
				cerr << "checksum error processing hex file line " << line_n << endl;
			}

			if (hexdata.type==0) {
				// store data into our flash memory buffer
				memory.put(hexdata.addr, hexdata.data, hexdata.length);
			} else {
				cout << "skip hex file line " << line_n << " with type " << hexdata.type << endl;
			}

			line_n++;
		}

		size_t addr=0;
		unsigned char buf[256];

		while (1){
			size_t s=memory.getContinuesBlock(addr, buf, sizeof(buf));
			if (!s) break;
			std::cout << " writing block at addr: " << std::dec << addr << " size: " << s << std::endl;

			while(1) {
				usleep(10000);
				// Send
				//std::cout << "send packet" << std::endl;
				gpb_packet_init(&packet, 0, packet_data, sizeof(packet_data));
				prepare_writeCmd(&packet, addr, buf, s);
				m_protocol->sendPacket( &packet);
				usleep(10000);
				int error=m_protocol->receivePacket(2000);

				if (error<0) {
					std::cout << "programmer protocol error: " << error << std::endl;
					return false;
				}

				if (error==0) {
					std::cout << "programmer timeout error: " << std::endl;
					continue;
				}

				break;
			} ;

			addr+=s;

		}
	}



	bool startApp()
	{
		gpb_packet_t packet;
		unsigned char packet_data[1000];

		gpb_packet_init(&packet, 0, packet_data, sizeof(packet_data));

		std::cout << "send start packet" << std::endl;
		gpb_packet_init(&packet, 0, packet_data, sizeof(packet_data));
		prepare_startCmd(&packet);
		m_protocol->sendPacket(&packet);
		usleep(10000);
		int error=m_protocol->receivePacket(2000);

		if (error<0) {
			std::cout << "programmer protocol error: " << error << std::endl;
			return false;
		}

		if (error==0) {
			std::cout << "programmer timeout error: " << std::endl;
			return false;
		}

		std::cout << "start app" << std::endl;

		return true;
	}

	void test_communication()
	{
		gpb_packet_t packet;
		unsigned char packet_data[1000];

		gpb_packet_init(&packet, 0, packet_data, sizeof(packet_data));

		size_t addr=0;

		while (1) {

			usleep(500000);
			gpb_packet_init(&packet, 0, packet_data, sizeof(packet_data));
			prepare_readCmd(&packet, addr, 128);
			m_protocol->sendPacket(&packet);
			int error=m_protocol->receivePacket(2000);

			addr+=128;

			const gpb_packet_t& rpacket=m_protocol->receivedPacket();

			if (error==1) {
				std::cout << "received packet! type: " << (int) rpacket.type << std::endl;
				if (rpacket.type==1) {
					// received Programmer ID
					std::stringstream s;
					for (int i=0;i<rpacket.size;i++) {
						s << rpacket.data[i];
					}
					std::cout << "Programmers ID: " << s.str() << std::endl;
				}
				else if (rpacket.type==3) {
					// received Programmer ID
					for (int i=0;i<rpacket.size;i++) {
						std::cout << std::hex << " 0x" << (((unsigned int)rpacket.data[i])&0xff);
					}
					std::cout << std::endl;
				}
			}
			if (error<0) {
				std::cout << "decoder error: " << error << std::endl;
			}
			if (error==0) {
				std::cout << "decoder timeout: " << std::endl;
				break;
			}

		}
	}

};

using namespace std;
using boost::filesystem::file_size;
namespace po = boost::program_options;

int main(int argc, char** argv)
{
	cout << "***** icescint GPB cpu firmware programmer - " << __DATE__ << " " << __TIME__ << endl;

	int panel=0;
	string filename;

	unsigned int     mask;
	bool didSomething = false;
	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
			("check,c", "check bootloader id")
		    ("filename,f", po::value<std::string>(&filename), "set .hex file to use")
#ifdef ARCH_AT91
		    ("panel,p", po::value<int>(&panel), "select panel to use")
#endif
			("write,w", "write hex file to flash")
			("verify,v", "verify hex file with flash")
			("test,t", "test communication")
			("start,s", "start application")
		;
	po::variables_map vm;
	try {
		po::store(
			po::command_line_parser(argc, argv).options(desc).allow_unregistered().run(),
		vm);
	} catch (boost::program_options::invalid_command_line_syntax &e) {
		cout << "error: " << e.what() << endl;
		return -1;
	}

	//po::store(po::command_line_parser(argc, argv).options(desc).positional(p).run(), vm);

#ifdef ARCH_AT91
	if (!vm.count("panel") || panel<0 || panel>7) {
		cerr << "you must select a panel 0..7 !" << endl;
		return 0
	}

	TaxiSerialTransport transport(panel);
#else
	USBSerialTransport transport(portname);
#endif

	GPBPacketProtocol protocol(&transport);
	GPBProgrammer programmer(&protocol);

	po::notify(vm);

	if (vm.count("help")) {
		cout << desc << "\n";
		return 0;
	}

	if (vm.count("check")) {

	} else if (vm.count("verify")) {
		cout << "verify hex file with flash content" << std::endl;

		if (!vm.count("filename")) {
			cerr << "a filename must be given with -f or --filename " << endl;
			return 0;
		}

		programmer.verifyFlash(filename);


	} else if (vm.count("write")) {
		cout << "write hex file with flash content" << std::endl;

		if (!vm.count("filename")) {
			cerr << "a filename must be given with -f or --filename " << endl;
			return 0;
		}

		//testWriteFlash();
		programmer.writeFlash(filename);
	} else if (vm.count("test")) {
		programmer.test_communication();
	} else if (vm.count("start")) {
		programmer.startApp();
	}
}
