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
#include "gpb/USBSerialTransport.hpp"
#include "gpb/GPBPacketProtocol.hpp"
#include <fstream>

#define  error_message(MSG...) (MSG)

#define PACKET_TYPE_TEST 	0x10
#define PACKET_TYPE_LGSEL 	0x11
#define PACKET_TYPE_RXLBSEL 0x12
#define PACKET_TYPE_PMT		0x13
#define PACKET_TYPE_STATUS	0x14


char portname[] = "/dev/ttyUSB0";



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

	GPBPacketProtocol* 	m_protocol;
	gpb_packet_t 		m_packet;
	unsigned char 		m_packet_data[1000];

	int prepare_testCmd(gpb_packet_t* _packet)
	{
		_packet->size=4;
		_packet->type=PACKET_TYPE_TEST;

		gpb_packet_write_u16(_packet, 0, 0x0201);
		gpb_packet_write_u16(_packet, 2, 0x0403);
		return 4;
	}

	int prepare_lgselCmd(gpb_packet_t* _packet, int _lgsel)
	{
		_packet->size=1;
		_packet->type=PACKET_TYPE_LGSEL;

		gpb_packet_write(_packet, 0, _lgsel);
		return 1;
	}

	int prepare_rxlbselCmd(gpb_packet_t* _packet, int _rxlbsel)
	{
		_packet->size=1;
		_packet->type=PACKET_TYPE_LGSEL;

		gpb_packet_write(_packet, 0, _rxlbsel);
		return 1;
	}

	int prepare_pmtCmd(gpb_packet_t* _packet, std::string _s)
	{
		_packet->size=_s.length();
		_packet->type=PACKET_TYPE_PMT;

		for (int i=0;i<_s.length();i++) {
			gpb_packet_write(_packet, i, _s[i]);
		}
		return _s.length();
	}
public:
	GPBClient(GPBPacketProtocol* _protocol)
	: m_protocol(_protocol)
	{
		gpb_packet_init(&m_packet, 0, m_packet_data, sizeof(m_packet_data));
	}

	// sends test command, returns true, if test command reply was received successfully
	bool testCmd()
	{
		prepare_testCmd(&m_packet);
		m_protocol->sendPacket(&m_packet);

		m_protocol->receivePacket(TIMEOUT);
		const gpb_packet_t& p=m_protocol->receivedPacket();
		if (p.type!=PACKET_TYPE_TEST) return false;
		return true;
	}

	// sends test command, returns true, if test command reply was received successfully
	bool pmt(std::string _command, std::string& _reply)
	{
		prepare_pmtCmd(&m_packet, _command);
		m_protocol->sendPacket(&m_packet);

		m_protocol->receivePacket(TIMEOUT);
		const gpb_packet_t& p=m_protocol->receivedPacket();
		if (p.type!=PACKET_TYPE_PMT) {

			return false;
		}
		_reply = std::string((char*)p.data, p.data_size);
		return true;
	}

	bool setLgSel(int _lgsel)
	{
		prepare_lgselCmd(&m_packet, _lgsel);
		m_protocol->sendPacket(&m_packet);
		m_protocol->receivePacket(TIMEOUT);
		const gpb_packet_t& p=m_protocol->receivedPacket();
		if (p.type!=PACKET_TYPE_LGSEL) return false;
		return true;
	}

	bool setRxlbSel(int _value)
	{
		prepare_rxlbselCmd(&m_packet, _value);
		m_protocol->sendPacket(&m_packet);
		m_protocol->receivePacket(TIMEOUT);
		const gpb_packet_t& p=m_protocol->receivedPacket();
		if (p.type!=PACKET_TYPE_RXLBSEL) return false;
		return true;
	}

	bool getStatus(bool& _lgsel, bool& _rxlbsel)
	{
		m_packet.size=0;
		m_packet.type=PACKET_TYPE_STATUS;
		m_protocol->sendPacket(&m_packet);
		m_protocol->receivePacket(TIMEOUT);
		const gpb_packet_t& p=m_protocol->receivedPacket();
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
	GPBPacketProtocol packetProtocol(&transport);
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
