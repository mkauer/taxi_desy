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
#include <fstream>

#define  error_message(MSG...) (MSG)

#define PACKET_TYPE_TEST 	0x10
#define PACKET_TYPE_LGSEL 	0x11
#define PACKET_TYPE_RXLBSEL 0x12
#define PACKET_TYPE_PMT		0x13
#define PACKET_TYPE_STATUS	0x14


char portname[] = "/dev/ttyUSB0";

class IIOTransport
{
public:
	virtual ~IIOTransport()
	{}
	virtual void write(void* _data, size_t _size) = 0;
	virtual int read(void* _data, size_t _size) = 0;
};

class USBSerialTransport : public IIOTransport
{
private:
	int m_fd;

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

public:
	USBSerialTransport(const char* _device)
	{
		m_fd = open (_device, O_RDWR | O_NOCTTY | O_SYNC);
		if (m_fd < 0)
		{
		        error_message ("error %d opening %s: %s", errno, portname, strerror (errno));
		        return ;
		}

		set_interface_attribs (m_fd, B9600, 0); // set speed to 115,200 bps, 8n1 (no parity)
	}
	~USBSerialTransport()
	{
		close(m_fd);
	}

	virtual void write(void* _data, size_t _size)
	{
		::write (m_fd, _data, _size); // send data
	}
	virtual int read(void* _data, size_t _size)
	{
		return ::read(m_fd, _data, _size);
	}
};


class PacketTransceiver
{
private:
	IIOTransport* m_transport;
	packetDecoder_t m_decoder;
	packet_t m_packet;
	void* 	 m_packet_data;
	size_t 	 m_packet_data_size;

public:
	PacketTransceiver(IIOTransport* _transport, size_t _bufferSize=1000)
	: m_transport(_transport)
	{
		m_packet_data=malloc(_bufferSize);
		m_packet_data_size=_bufferSize;
		packet_init(&m_packet, 0, m_packet_data, m_packet_data_size);
		packetDecoder_init(&m_decoder, &m_packet);
	}
	~PacketTransceiver()
	{
		free(m_packet_data);
	}

	// Sends packet to file descriptor
	int sendPacket(packet_t* _packet)
	{
		unsigned char buf[1000];
		int size=packet_serialize(_packet, buf, sizeof(buf));
		if (size<0) return -1; // error

		m_transport->write (buf, size); // send packet
		return size;
	}

	// Sends packet to file descriptor
	// returns 1 if packet was received
	// returns 0 on timeout
	int receivePacket(int _timeout)
	{
		boost::posix_time::ptime timeoutTime=boost::posix_time::microsec_clock::local_time()+boost::posix_time::milliseconds(_timeout);

		bool checksumError=false;

		while(timeoutTime>boost::posix_time::microsec_clock::local_time()) {
			unsigned char buf [1000];
			int n = m_transport->read(buf, sizeof buf);  	// read up to 100 characters if ready

			for (int i=0;i<n;i++) {
				//std::cout << std::hex << " 0x" << ((int)buf[i]);
				int error=packetDecoder_processData(&m_decoder, buf[i]);
				if (error==1) {
					return 1; // packet received!
				}
			}
		}

		return 0; // timeout appeared
	}

	const packet_t& receivedPacket() const
	{
		return m_packet;
	}
};


int prepare_testCmd(packet_t* _packet)
{
	if (_packet->data_size<4) return 0; // error, packet does not fit
	_packet->size=4;
	_packet->type=PACKET_TYPE_TEST;

	packet_write_u16(_packet, 0, 0x0201);
	packet_write_u16(_packet, 2, 0x0403);
	return 4;
}

int prepare_lgselCmd(packet_t* _packet, int _lgsel)
{
	if (_packet->data_size<4) return 0; // error, packet does not fit
	_packet->size=1;
	_packet->type=PACKET_TYPE_LGSEL;

	packet_write(_packet, 0, _lgsel);
	return 1;
}

int prepare_rxlbselCmd(packet_t* _packet, int _rxlbsel)
{
	if (_packet->data_size<4) return 0; // error, packet does not fit
	_packet->size=1;
	_packet->type=PACKET_TYPE_LGSEL;

	packet_write(_packet, 0, _rxlbsel);
	return 1;
}

int prepare_pmtCmd(packet_t* _packet, std::string _s)
{
	if (_packet->data_size<4) return 0; // error, packet does not fit
	_packet->size=1;
	_packet->type=PACKET_TYPE_LGSEL;

	for (int i=0;i<_s.length();i++) {
		packet_write(_packet, i, _s[i]);
	}
	return _s.length()+3;
}

#define PACKET_TYPE_TEST 	0x10
#define PACKET_TYPE_LGSEL 	0x11
#define PACKET_TYPE_RXLBSEL 0x12
#define PACKET_TYPE_PMT		0x13
#define PACKET_TYPE_STATUS	0x14

class GPBClient
{
private:
	enum{
		TIMEOUT = 1000


	};

	PacketTransceiver* 	m_transceiver;
	packet_t 			m_packet;
	unsigned char 		m_packet_data[1000];

	int prepare_testCmd(packet_t* _packet)
	{
		_packet->size=4;
		_packet->type=PACKET_TYPE_TEST;

		packet_write_u16(_packet, 0, 0x0201);
		packet_write_u16(_packet, 2, 0x0403);
		return 4;
	}

	int prepare_lgselCmd(packet_t* _packet, int _lgsel)
	{
		_packet->size=1;
		_packet->type=PACKET_TYPE_LGSEL;

		packet_write(_packet, 0, _lgsel);
		return 1;
	}

	int prepare_rxlbselCmd(packet_t* _packet, int _rxlbsel)
	{
		_packet->size=1;
		_packet->type=PACKET_TYPE_LGSEL;

		packet_write(_packet, 0, _rxlbsel);
		return 1;
	}

	int prepare_pmtCmd(packet_t* _packet, std::string _s)
	{
		_packet->size=_s.length();
		_packet->type=PACKET_TYPE_PMT;

		for (int i=0;i<_s.length();i++) {
			packet_write(_packet, i, _s[i]);
		}
		return _s.length();
	}
public:
	GPBClient(PacketTransceiver* _transceiver)
	: m_transceiver(_transceiver)
	{
		packet_init(&m_packet, 0, m_packet_data, sizeof(m_packet_data));
	}

	// sends test command, returns true, if test command reply was received successfully
	bool testCmd()
	{
		prepare_testCmd(&m_packet);
		m_transceiver->sendPacket(&m_packet);

		m_transceiver->receivePacket(TIMEOUT);
		const packet_t& p=m_transceiver->receivedPacket();
		if (p.type!=PACKET_TYPE_TEST) return false;
		return true;
	}

	// sends test command, returns true, if test command reply was received successfully
	bool pmt(std::string _command, std::string& _reply)
	{
		prepare_pmtCmd(&m_packet, _command);
		m_transceiver->sendPacket(&m_packet);

		m_transceiver->receivePacket(TIMEOUT);
		const packet_t& p=m_transceiver->receivedPacket();
		if (p.type!=PACKET_TYPE_PMT) {

			return false;
		}
		_reply = std::string((char*)p.data, p.data_size);
		return true;
	}

	bool setLgSel(int _lgsel)
	{
		prepare_lgselCmd(&m_packet, _lgsel);
		m_transceiver->sendPacket(&m_packet);
		m_transceiver->receivePacket(TIMEOUT);
		const packet_t& p=m_transceiver->receivedPacket();
		if (p.type!=PACKET_TYPE_LGSEL) return false;
		return true;
	}

	bool setRxlbSel(int _value)
	{
		prepare_rxlbselCmd(&m_packet, _value);
		m_transceiver->sendPacket(&m_packet);
		m_transceiver->receivePacket(TIMEOUT);
		const packet_t& p=m_transceiver->receivedPacket();
		if (p.type!=PACKET_TYPE_RXLBSEL) return false;
		return true;
	}

	bool getStatus(bool& _lgsel, bool& _rxlbsel)
	{
		m_packet.size=0;
		m_packet.type=PACKET_TYPE_STATUS;
		m_transceiver->sendPacket(&m_packet);
		m_transceiver->receivePacket(TIMEOUT);
		const packet_t& p=m_transceiver->receivedPacket();
		if (p.type!=PACKET_TYPE_RXLBSEL) return false;
		return true;
	}
};

using namespace std;
using boost::filesystem::file_size;
namespace po = boost::program_options;



int main(int argc, char** argv)
{
	cout << "***** icescint GPB client - " << __DATE__ << " " << __TIME__ << endl;

	string filename;

	unsigned int     mask;
	bool didSomething = false;
	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
			("test,t", "test communication")
		    ("pmt,p", po::value<std::string>(), "send pmt command")
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

	USBSerialTransport transport(portname);
	PacketTransceiver packetProtocol(&transport);
	GPBClient client(&packetProtocol);

	if (vm.count("test")) {
		if (client.testCmd()) {
			std::cout << "connection established!" << std::endl;
		} else {
			std::cout << "connection timeout!" << std::endl;
		}
		return 0;
	}

	if (vm.count("pmt")) {
		std::string reply;
		if (client.pmt(vm["pmt"].as<std::string>(), reply)) {
			std::cout << "reply: " << reply << std::endl;
		} else {
			std::cout << "connection timeout!" << std::endl;
		}
		return 0;
	}

}
