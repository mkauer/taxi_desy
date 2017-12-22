/*
 * GPBController.cpp
 *
 *  Created on: Dec 18, 2017
 *      Author: marekp
 */

#include "GPBController.hpp"

#include "gpb/TaxiSerialTransport.hpp"
#include <boost/shared_ptr.hpp>
#include <iosfwd>

#include <iostream>
#include <string>
#include <sstream>
#include <iomanip>

static const double voltageConversionFactor=1.812e-3;

int GPBController::stringHexToInt(std::string _string)
{
	int temp;
	std::stringstream interpreter;
	interpreter << std::hex << _string;
	interpreter >> temp;
	return temp;
}

GPBController::GPBController(GPBPacketProtocol* _protocol)
: m_protocol(_protocol),
  m_timeout(DEFAULT_TIMEOUT),
  m_retryCount(DEFAULT_RETRY_COUNT)
{
	gpb_packet_init(&m_packet, 0, m_packet_data, sizeof(m_packet_data));
}


// sends a packet and expects an answer with the same packet id
// sends automatically retry messages
// returns EOK, if command was successfully send
// returns command reply in _reply
GPBController::error_t  GPBController::sendPacket(const gpb_packet_t& _packet)
{
	m_protocol->sendPacket(&_packet);

	for (int i=0;i<m_retryCount;i++) {
		if (m_protocol->receivePacket(m_timeout/m_retryCount)) {
			const gpb_packet_t& p=m_protocol->receivedPacket();
			if (p.type==PACKET_TYPE_UNKNOWN) return EUNKNOWNCMD;
			if (p.type!=_packet.type) return EWRONGREPLY;
			return EOK;
		}
	}
	return ETIMEOUT;
}

bool GPBController::bootloader_startApp()
{
	gpb_packet_t packet;
	unsigned char packet_data[1000];
	gpb_packet_init(&packet, 0, packet_data, sizeof(packet_data));
	packet.size=0;
	packet.type=5;
	m_protocol->sendPacket(&packet);
	int error=m_protocol->receivePacket(2000);

	if (error<0) {
		std::cout << "programmer protocol error: " << error << std::endl;
		return false;
	}

	if (error==0) {
		std::cout << "programmer timeout error: " << std::endl;
		return false;
	}
	return true;
}

// sends test command
// returns EOK, if test command reply was received successfully
GPBController::error_t GPBController::testCmd()
{
	m_packet.size=4;
	m_packet.type=PACKET_TYPE_TEST;
	gpb_packet_write_u16(&m_packet, 0, 0x0201);
	gpb_packet_write_u16(&m_packet, 2, 0x0403);
	error_t err=sendPacket(m_packet);
	if (err!=EOK) return err;
	return EOK;
}

// sends command to Hamamatsu processor
// returns EOK, if command was successfully send
// returns command reply in _reply
GPBController::error_t  GPBController::sendPmtCommand(std::string _command, std::string& _reply)
{
	m_packet.size=_command.length();
	m_packet.type=PACKET_TYPE_PMT;

	if (_command.length()>m_packet.data_size) return EPARAMETER;

	for (int i=0;i<_command.length();i++) m_packet.data[i]=_command[i];

	error_t err=sendPacket(m_packet);
	if (err!=EOK) return err;

	const gpb_packet_t& p=m_protocol->receivedPacket();
	_reply = std::string((char*)p.data, p.size);
	return EOK;
}

// sends command to Hamamatsu processor
// returns EOK, if command was successfully send
// returns command reply in _reply
GPBController::error_t  GPBController::pmt_getTemperature(int& _value)
{
	std::string reply;
	error_t err=sendPmtCommand("HGT",reply);
	if(err!=EOK) return err;

	std::string cmd=std::string(&reply[0],&reply[3]);
	std::string value=std::string(&reply[3],&reply[7]);

	if (cmd!="hgt") return EPMTERROR;

	_value = stringHexToInt(value);
	return EOK;
}

// sends set HV command to Hamamatsu processor
// returns EOK, if command was successfully send
GPBController::error_t  GPBController::pmt_setHV(double _voltage)
{
	std::stringstream command;
	std::string reply;
	command << "HBV" << std::setfill('0') << std::setw(4) << std::hex << int(_voltage/voltageConversionFactor);
	error_t err=sendPmtCommand(command.str(), reply);
	if(err!=EOK) return err;

	std::string cmd=std::string(&reply[0],&reply[3]);

	if (cmd!="hbv") return EPMTERROR;

	return EOK;
}

// sends set HV on/off command to Hamamatsu processor
// returns EOK, if command was successfully send
GPBController::error_t  GPBController::pmt_power(bool _onoff)
{
	std::string reply;

	if (_onoff) {
		error_t err=sendPmtCommand("HON", reply);
		if(err!=EOK) return err;
		std::string cmd=std::string(&reply[0],&reply[3]);
		if (cmd!="hon") return EPMTERROR;
		return EOK;
	} else {
		error_t err=sendPmtCommand("HOF", reply);
		if(err!=EOK) return err;
		std::string cmd=std::string(&reply[0],&reply[3]);
		if (cmd!="hof") return EPMTERROR;
		return EOK;
	}
}

// set lgsel pin to high (1) or low (0)
// returns EOK on success
GPBController::error_t  GPBController::setLgSel(int _lgsel)
{
	m_packet.size=1;
	m_packet.type=PACKET_TYPE_LGSEL;
	m_packet.data[0]=_lgsel;
	return sendPacket(m_packet);
}

// set rxlbsel pin to high (1) or low (0)
// returns EOK on success
GPBController::error_t  GPBController::setRxlbSel(int _value)
{
	m_packet.size=1;
	m_packet.type=PACKET_TYPE_RXLBSEL;
	m_packet.data[0]=_value;
	return sendPacket(m_packet);
}

// requests actual status of lgsel and rxlbsel
// returns EOK on success and in _lgsel and _rxlbsel 1 = high and 0 = low status
GPBController::error_t  GPBController::getStatus(bool& _lgsel, bool& _rxlbsel)
{
	m_packet.size=0;
	m_packet.type=PACKET_TYPE_STATUS;
	error_t err=sendPacket(m_packet);
	if (err!=EOK) return err;

	const gpb_packet_t& p=m_protocol->receivedPacket();
	_lgsel=p.data[0]?true:false;
	_rxlbsel=p.data[1]?true:false;
	return EOK;
}

// requests software version
// returns EOK on success and
// returns in version bit 15..8 major version and in bit 7..0 minor version
GPBController::error_t  GPBController::getVersion(uint16_t& _version)
{
	m_packet.size=0;
	m_packet.type=PACKET_TYPE_VERSION;
	error_t err=sendPacket(m_packet);
	if (err!=EOK) return err;

	const gpb_packet_t& p=m_protocol->receivedPacket();
	_version=p.data[0] | (p.data[1] << 8);
	return EOK;
}

// returns state
GPBController::state_t GPBController::getState(void)
{
	m_packet.size=0;
	m_packet.type=PACKET_TYPE_VERSION;

	error_t err=sendPacket(m_packet);
	const gpb_packet_t& p=m_protocol->receivedPacket();
	if (err==EOK) return STATE_APPLICATION;
	if (err==EWRONGREPLY) {
		if (p.type==4) return STATE_BOOTLOADER; // answer is 4 for unknown packets from boot loader

		return STATE_UNKNOWN;					// cannot tell what happened, incompatible app or wrong bootloader
	}
	if (err==ETIMEOUT) {
		return STATE_UNCONNECTED;				// now answer, panel seems not connected
	}

	return STATE_UNKNOWN;
}

	// tries to initialize the panel, if it is in strange state
	bool GPBController::initialize(bool _verbose)
	{
		GPBController::state_t state=getState();
		bool reboot=false;
#define __VERBOSE(STATEMENT) do { if (_verbose) STATEMENT; } while(0)
		if (state==GPBController::STATE_UNCONNECTED) {
			__VERBOSE(std::cerr << "error: panel seems not to be connected or has old firmware, trying reboot" << std::endl);
			reboot=true;
		} else if (state==GPBController::STATE_BOOTLOADER) {
			__VERBOSE(std::cerr << "warning: panel is in bootloader mode, trying to reboot" << std::endl);
			reboot=true;
		} else {
//			__VERBOSE( std::cout << "panel is in state " << toString(state) << std::endl);
		}

		if (reboot) {
			__VERBOSE(std::cout << "rebooting (power cycle) panel..." << std::endl);

			m_protocol->transport()->reboot();

			if (!bootloader_startApp()) {
				__VERBOSE(std::cerr << "error: failed to start application after reboot!" << std::endl);

				m_protocol->transport()->reboot();

				__VERBOSE(std::cout << "trying automatic boot mode ");
				for (int i=0;i<7;i++) {
					sleep(1);
					__VERBOSE(std::cout << ".");
					__VERBOSE(std::cout.flush());
				}
				__VERBOSE(std::cout << std::endl);
			} else {
				sleep(1);
			}
		}

		state=getState();
		if (state!=GPBController::STATE_APPLICATION) {
			__VERBOSE(
			std::cerr << "error panel ";
			switch (state) {
			case GPBController::STATE_BOOTLOADER:
				std::cerr << "is still in bootloader mode!" ;
				break;
			case GPBController::STATE_UNCONNECTED:
				std::cerr << "seems to be unconnected!" ;
				break;
			default:
				std::cerr << "state is unknown!";
				break;
			}
			std::cerr << std::endl;
			);
			return false;
		}
#undef __VERBOSE

		return true;
	}

class GPBControllerInstance
{
public:
	TaxiSerialTransport m_transportSerial;
	GPBPacketProtocol 	m_packetProtocol;
	GPBController		m_controller;

	GPBControllerInstance(int _panel)
	: m_transportSerial(_panel),
	  m_packetProtocol(&m_transportSerial),
	  m_controller(&m_packetProtocol)
	{}
};

static std::map<int, boost::shared_ptr<GPBControllerInstance> > controller;

GPBController& getGPBController(int _panel)
{
	if (_panel<0 || _panel>7) throw std::runtime_error("invalid panel, cannot instantiate gpb controller");
	if (controller[_panel]) return controller[_panel].get()->m_controller;
	controller[_panel]=boost::shared_ptr<GPBControllerInstance>(new GPBControllerInstance(_panel));
	return controller[_panel].get()->m_controller;
}
