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
#include "protocol.h"
#include "hexfile.h"
#include <fstream>

#define  error_message(MSG...) (MSG)

int set_interface_attribs (int fd, int speed, int parity)
{
        struct termios tty;
        memset (&tty, 0, sizeof tty);
        if (tcgetattr (fd, &tty) != 0)
        {

        		std::cerr << "error " << errno << " from tcgetattr" << std::endl;
                return -1;
        }

        cfsetospeed (&tty, speed);
        cfsetispeed (&tty, speed);

        /*
        tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;     // 8-bit chars
        // disable IGNBRK for mismatched speed tests; otherwise receive break
        // as \000 chars
        tty.c_iflag &= ~IGNBRK;         // disable break processing
        tty.c_lflag = 0;                // no signaling chars, no echo,
                                        // no canonical processing
        tty.c_oflag = 0;                // no remapping, no delays
        tty.c_cc[VMIN]  = 0;            // read doesn't block
        tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

        tty.c_iflag &= ~(IXON | IXOFF | IXANY); // shut off xon/xoff ctrl
//        tty.c_iflag |= (IXON | IXOFF | IXANY); // shut off xon/xoff ctrl

        tty.c_cflag |= (CLOCAL | CREAD);// ignore modem controls,
        tty.c_cflag &= ~(PARENB | PARODD); // shut off parity
        tty.c_cflag |= parity;
        tty.c_cflag &= ~CSTOPB;
        tty.c_cflag &= ~CRTSCTS;
        */

        tty.c_iflag = 0;

        /* output modes - clear giving: no post processing such as NL to CR+NL */
        tty.c_oflag &= ~(OPOST|OLCUC|ONLCR|OCRNL|ONLRET|OFDEL);

        /* control modes - set 8 bit chars */
        tty.c_cflag |= ( CS8 ) ;

        /* local modes - clear giving: echoing off, canonical off (no erase with
        backspace, ^U,...), no extended functions, no signal chars (^Z,^C) */
        tty.c_lflag &= ~(ECHO | ECHOE | ICANON | IEXTEN | ISIG);


        if (tcsetattr (fd, TCSANOW, &tty) != 0)
        {
                error_message ("error %d from tcsetattr", errno);
                return -1;
        }
        return 0;
}

void
set_blocking (int fd, int should_block)
{
        struct termios tty;
        memset (&tty, 0, sizeof tty);
        if (tcgetattr (fd, &tty) != 0)
        {
                error_message ("error %d from tggetattr", errno);
                return;
        }

        tty.c_cc[VMIN]  = should_block ? 1 : 0;
        tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

        if (tcsetattr (fd, TCSANOW, &tty) != 0)
                error_message ("error %d setting term attributes", errno);
}

char portname[] = "/dev/ttyUSB0";

// Sends packet to file descriptor
int sendPacket(int fd, packet_t* _packet)
{
	unsigned char buf[1000];

	int size=packet_serialize(_packet, buf, sizeof(buf));

	if (size<0) return -1; // error

/*	for (int i=0;i<size;i++) {
		std::cout << std::hex << (((unsigned int)buf[i])&0xff) << " ";
	}
	std::cout << std::endl;
*/
	write (fd, buf, size); // send packet

	return size;
}

// Sends packet to file descriptor
int receivePacket(int fd, packetDecoder_t* _decoder, int _timeout)
{
	boost::posix_time::ptime timeoutTime=boost::posix_time::microsec_clock::local_time()+boost::posix_time::milliseconds(_timeout);

	bool checksumError=false;

	while(timeoutTime>boost::posix_time::microsec_clock::local_time()) {
		unsigned char buf [1000];
		int n = read (fd, buf, sizeof buf);  	// read up to 100 characters if ready

/*		if (n>0) {
			for (int i=0;i<n;i++) {
				std::cout << std::hex << " 0x" << (((unsigned int)buf[i])&0xff);
			}
			std::cout << std::endl;
		}
*/		for (int i=0;i<n;i++) {
			int error=packetDecoder_processData(_decoder, buf[i]);
			if (error==1) return 1; // packet received!
		}

//		if (n==0) usleep(100000);
//		std::cout << "waiting..." << std::endl;
	}
	return 0; // timeout appeared
}

int prepare_readCmd(packet_t* _packet, unsigned short _addr, unsigned short _length)
{
	if (_packet->data_size<4) return 0; // error, packet does not fit
	_packet->size=4;
	_packet->type=3;

	packet_write_u16(_packet, 0, _addr);
	packet_write_u16(_packet, 2, _length);

	return 4;
}

int prepare_startCmd(packet_t* _packet)
{
	_packet->size=0;
	_packet->type=5;
	return 0;
}

int prepare_writeCmd(packet_t* _packet, unsigned short _addr, void* _data, unsigned short _length)
{
	size_t s=_length+2;
	if (_packet->data_size<s) return 0; // error, packet does not fit
	_packet->size=s;
	_packet->type=2;

	packet_write_u16(_packet, 0, _addr);

	unsigned char* p=reinterpret_cast<unsigned char*>(_data);
	for (int i=0;i<_length;i++) {
		packet_write(_packet, i+2, p[i]);
	}

	return s;
}


class FlashMemory
{
public:
	unsigned char* buf;
	unsigned char* used;
	size_t bufSize;

	FlashMemory()
	{
		bufSize=128*1024;
		buf=reinterpret_cast<unsigned char*>(malloc(bufSize));
		used=reinterpret_cast<unsigned char*>(malloc(bufSize));
		memset(buf,0xff,bufSize);
		memset(used,0,bufSize);
	}
	~FlashMemory()
	{
		free(buf);
		free(used);
	}
	void clear()
	{
		memset(buf,0xff,bufSize);
		memset(used,0,bufSize);
	}
	void put(size_t _addr, void* _data, size_t _size)
	{
		if (_addr+_size>=bufSize) return; // error buffer overflow!
		unsigned char* p=&reinterpret_cast<unsigned char*>(buf)[_addr];
		unsigned char* u=&reinterpret_cast<unsigned char*>(used)[_addr];
		memcpy(p, _data, _size);
		memset(u, 1, _size);
	}

	// returns number of continues allocated bytes starting with _addr
	// but not more than _maxSize
	bool getNextBlock(size_t& _addr)
	{
		size_t addr=_addr;
		if (addr>=bufSize) return false; // error buffer overflow!
		for (int i=addr;i<bufSize;i++) {
			if (used[i]) {
				_addr=i;
				return true; // found
			}
		}
		return false; // none found
	}

	// returns number of continues allocated bytes starting with _addr
	// but not more than _maxSize
	size_t getContinuesBlockSize(size_t _addr, size_t _maxSize)
	{
		if (_addr>=bufSize) return 0; // error buffer overflow!
		size_t s=0;
		for (int i=_addr;i<bufSize;i++) {
			if (!used[i]) break;
			s++;
			if (s>=_maxSize) break;
		}
		return s;
	}

	// copies _size from data buffer
	// returns number of bytes copied
	size_t getContinuesBlock(size_t& _addr, void* _data, size_t _size)
	{
		if (_addr>=bufSize) return 0; // error buffer overflow!
		if (_addr+_size>=bufSize) { // truncate
			_size=bufSize-_addr;
		}

		// try to find next block of used data
		if (!getNextBlock(_addr)) {
			std::cout << "no next block found!" <<std::endl;
			return 0; // none found, exit
		} else {
			std::cout << "using addr : 0x" << std::hex << _addr <<std::endl;
		}

		// check size of bytes available for usage
		_size=getContinuesBlockSize(_addr, _size);
		if (!_size) {
			std::cout << "no continues block found!" <<std::endl;
			return 0; // nothing to copy found
		}

		unsigned char* p=&(reinterpret_cast<unsigned char*>(buf))[_addr];
		memcpy(_data, p, _size);
		return _size;
	}

};


using namespace std;
using boost::filesystem::file_size;
namespace po = boost::program_options;

bool verifyFlash(std::string _filename)
{
	int fd = open (portname, O_RDWR | O_NOCTTY | O_SYNC);
	if (fd < 0)
	{
		error_message ("error %d opening %s: %s", errno, portname, strerror (errno));
		return false;
	}

	set_interface_attribs (fd, B9600, 0); // set speed to 115,200 bps, 8n1 (no parity)

	packetDecoder_t decoder;
	packet_t packet;
	unsigned char packet_data[1000];

	packet_init(&packet, 0, packet_data, sizeof(packet_data));
	packetDecoder_init(&decoder, &packet);

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
			packet_init(&packet, 0, packet_data, sizeof(packet_data));
			prepare_readCmd(&packet, hexdata.addr, hexdata.length);
			sendPacket(fd, &packet);
			int error=receivePacket(fd, &decoder, 2000);

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

		for (int i=0;i<packet.size;i++) {

			if (hexdata.data[i]!=packet.data[i]) {
				std::cout << std::endl << "verify FAILED! pos:" << i << " " << (((unsigned int)packet.data[i])&0xff) << " != " << (((unsigned int)hexdata.data[i])&0xff) << std::endl;

				cout << "hex line: " << line_n << " type: " << dec << hexdata.type << " addr: 0x" << hex << hexdata.addr << " bytes " << dec << hexdata.length << " checksum: " << ((int)c) << endl;

//				std::cout << std::hex << " 0x" << (((unsigned int)packet.data[i])&0xff);

				std::cout << "flash  : ";
				for (int i=0;i<packet.size;i++) {
					std::cout << std::hex << " 0x" << (((unsigned int)packet.data[i])&0xff);
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

//	while (1) {

/*		usleep(500000);
		packet_init(&packet, 0, packet_data, sizeof(packet_data));
		prepare_readCmd(&packet, 0, 100);
		sendPacket(fd, &packet);
		int error=receivePacket(fd, &decoder, 2000);

		if (error==1) {
			std::cout << "received packet! type: " << (int) packet.type << std::endl;
			if (packet.type==1) {
				// received Programmer ID
				std::stringstream s;
				for (int i=0;i<packet.size;i++) {
					s << packet.data[i];
				}
				std::cout << "Programmers ID: " << s.str() << std::endl;
			}
			else if (packet.type==3) {
				// received Programmer ID
				for (int i=0;i<packet.size;i++) {
					std::cout << std::hex << " 0x" << (((unsigned int)packet.data[i])&0xff);
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
		}*/

//	}

}

bool testWriteFlash()
{
	int fd = open (portname, O_RDWR | O_NOCTTY | O_SYNC);
	if (fd < 0)
	{
		error_message ("error %d opening %s: %s", errno, portname, strerror (errno));
		return false;
	}

	set_interface_attribs (fd, B9600, 0); // set speed to 115,200 bps, 8n1 (no parity)

	packetDecoder_t decoder;
	packet_t packet;
	unsigned char packet_data[1000];

	packet_init(&packet, 0, packet_data, sizeof(packet_data));
	packetDecoder_init(&decoder, &packet);

	unsigned char buf[64];
	for (int i=0;i<sizeof(buf);i++) buf[i]=i;

	std::cout << "send packet test write packet" << std::endl;
	packet_init(&packet, 0, packet_data, sizeof(packet_data));
	prepare_writeCmd(&packet, 0xf000, buf, sizeof(buf));
	sendPacket(fd, &packet);

}

bool writeFlash(std::string _filename)
{
	int fd = open (portname, O_RDWR | O_NOCTTY | O_SYNC);
	if (fd < 0)
	{
		error_message ("error %d opening %s: %s", errno, portname, strerror (errno));
		return false;
	}

	set_interface_attribs (fd, B9600, 0); // set speed to 115,200 bps, 8n1 (no parity)

	packetDecoder_t decoder;
	packet_t packet;
	unsigned char packet_data[1000];

	packet_init(&packet, 0, packet_data, sizeof(packet_data));
	packetDecoder_init(&decoder, &packet);

	FlashMemory memory;

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
			std::cout << "send packet" << std::endl;
			packet_init(&packet, 0, packet_data, sizeof(packet_data));
			prepare_writeCmd(&packet, addr, buf, s);
			sendPacket(fd, &packet);
			usleep(10000);
			int error=receivePacket(fd, &decoder, 2000);

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
	int fd = open (portname, O_RDWR | O_NOCTTY | O_SYNC);
	if (fd < 0)
	{
		error_message ("error %d opening %s: %s", errno, portname, strerror (errno));
		return false;
	}

	set_interface_attribs (fd, B9600, 0); // set speed to 115,200 bps, 8n1 (no parity)

	packetDecoder_t decoder;
	packet_t packet;
	unsigned char packet_data[1000];

	packet_init(&packet, 0, packet_data, sizeof(packet_data));
	packetDecoder_init(&decoder, &packet);

	std::cout << "send start packet" << std::endl;
	packet_init(&packet, 0, packet_data, sizeof(packet_data));
	prepare_startCmd(&packet);
	sendPacket(fd, &packet);
	usleep(10000);
	int error=receivePacket(fd, &decoder, 2000);

	if (error<0) {
		std::cout << "programmer protocol error: " << error << std::endl;
		return false;
	}

	if (error==0) {
		std::cout << "programmer timeout error: " << std::endl;
		return false;
	}

	std::cout << "start app" << std::endl;


}

void test_communication()
{
	int fd = open (portname, O_RDWR | O_NOCTTY | O_SYNC);
	if (fd < 0)
	{
	        error_message ("error %d opening %s: %s", errno, portname, strerror (errno));
	        return ;
	}

	set_interface_attribs (fd, B9600, 0); // set speed to 115,200 bps, 8n1 (no parity)
//	set_blocking (fd, 1	);                	// set no blocking

	//sendPacketType(fd, 3, 0, 0);

	packetDecoder_t decoder;
	packet_t packet;
	unsigned char packet_data[1000];

	packet_init(&packet, 0, packet_data, sizeof(packet_data));
	packetDecoder_init(&decoder, &packet);

	size_t addr=0;

	while (1) {

		usleep(500000);
		packet_init(&packet, 0, packet_data, sizeof(packet_data));
		prepare_readCmd(&packet, addr, 128);
		sendPacket(fd, &packet);
		int error=receivePacket(fd, &decoder, 2000);

		addr+=128;

		if (error==1) {
			std::cout << "received packet! type: " << (int) packet.type << std::endl;
			if (packet.type==1) {
				// received Programmer ID
				std::stringstream s;
				for (int i=0;i<packet.size;i++) {
					s << packet.data[i];
				}
				std::cout << "Programmers ID: " << s.str() << std::endl;
			}
			else if (packet.type==3) {
				// received Programmer ID
				for (int i=0;i<packet.size;i++) {
					std::cout << std::hex << " 0x" << (((unsigned int)packet.data[i])&0xff);
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

int main(int argc, char** argv)
{
	cout << "***** icescint GPB cpu firmware programmer - " << __DATE__ << " " << __TIME__ << endl;

	string filename;

	unsigned int     mask;
	bool didSomething = false;
	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
			("check,c", "check bootloader id")
		    ("filename,f", po::value<std::string>(&filename), "set .hex file to use")
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

		verifyFlash(filename);


	} else if (vm.count("write")) {
		cout << "write hex file with flash content" << std::endl;

		if (!vm.count("filename")) {
			cerr << "a filename must be given with -f or --filename " << endl;
			return 0;
		}

		//testWriteFlash();
		writeFlash(filename);
	} else if (vm.count("test")) {
		test_communication();
	} else if (vm.count("start")) {
		startApp();
	}

/*
	int fd = open (portname, O_RDWR | O_NOCTTY | O_SYNC);
	if (fd < 0)
	{
	        error_message ("error %d opening %s: %s", errno, portname, strerror (errno));
	        return 0;
	}

	set_interface_attribs (fd, B9600, 0); // set speed to 115,200 bps, 8n1 (no parity)
//	set_blocking (fd, 1	);                	// set no blocking

	//sendPacketType(fd, 3, 0, 0);

	packetDecoder_t decoder;
	packet_t packet;
	unsigned char packet_data[1000];

	packet_init(&packet, 0, packet_data, sizeof(packet_data));
	packetDecoder_init(&decoder, &packet);


	while (1) {

		usleep(500000);
		packet_init(&packet, 0, packet_data, sizeof(packet_data));
		prepare_readCmd(&packet, 0, 100);
		sendPacket(fd, &packet);
		int error=receivePacket(fd, &decoder, 2000);

		if (error==1) {
			std::cout << "received packet! type: " << (int) packet.type << std::endl;
			if (packet.type==1) {
				// received Programmer ID
				std::stringstream s;
				for (int i=0;i<packet.size;i++) {
					s << packet.data[i];
				}
				std::cout << "Programmers ID: " << s.str() << std::endl;
			}
			else if (packet.type==3) {
				// received Programmer ID
				for (int i=0;i<packet.size;i++) {
					std::cout << std::hex << " 0x" << (((unsigned int)packet.data[i])&0xff);
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

	}*/
}
