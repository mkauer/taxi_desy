/*
 * GPBController.hpp
 *
 *  Created on: Dec 18, 2017
 *      Author: marekp
 */

#ifndef ICESCINT_GPB_CLIENT_GPBCONTROLLER_HPP_
#define ICESCINT_GPB_CLIENT_GPBCONTROLLER_HPP_

#include <gpb/gpb_protocol.h>
#include <stdint.h>
#include "gpb/GPBPacketProtocol.hpp"
#include <string>


static const double voltageConversionFactor=1.812e-3;

class GPBController
{
public:
	typedef enum {
		EOK 	 	= 0,
		ETIMEOUT 	= 1,
		EUNKNOWNCMD = 2,
		EWRONGREPLY = 3,
		EPMTERROR   = 4,
		EPARAMETER  = 5
	} error_t;

	typedef enum {
		STATE_UNCONNECTED,
		STATE_APPLICATION,
		STATE_BOOTLOADER,
		STATE_UNKNOWN
	} state_t;

	const char* toString(error_t _errorCode)
	{
#define __ECODE(NAME) case NAME: return #NAME
		switch(_errorCode) {
		case EOK : return "OK";
		__ECODE(ETIMEOUT);
		__ECODE(EUNKNOWNCMD);
		__ECODE(EWRONGREPLY);
		__ECODE(EPMTERROR);
		__ECODE(EPARAMETER);
		default:
			return "Unknown Error Code";
		}
#undef __ECODE
	}

	const char* toString(state_t _errorCode)
	{
#define __ECODE(NAME) case NAME: return #NAME
		switch(_errorCode) {
		__ECODE(STATE_UNCONNECTED);
		__ECODE(STATE_APPLICATION);
		__ECODE(STATE_BOOTLOADER);
		__ECODE(STATE_UNKNOWN);
		default:
			return "Unknown State Code";
		}
#undef __ECODE
	}

private:


	enum{
		// default parameter
		DEFAULT_TIMEOUT = 500,
		DEFAULT_RETRY_COUNT = 3,

		// Packet type definitions
		PACKET_TYPE_TEST 	= 0x10,
		PACKET_TYPE_LGSEL 	= 0x11,
		PACKET_TYPE_RXLBSEL = 0x12,
		PACKET_TYPE_PMT		= 0x13,
		PACKET_TYPE_STATUS	= 0x14,
		PACKET_TYPE_UNKNOWN	= 0x15,
		PACKET_TYPE_VERSION	= 0x16,
	};


	GPBPacketProtocol* 	m_protocol;
	gpb_packet_t 		m_packet;
	unsigned char 		m_packet_data[1000];
	int 				m_timeout;
	int					m_retryCount;

	int stringHexToInt(std::string _string);

public:
	GPBController(GPBPacketProtocol* _protocol);

	// sends a packet and expects an answer with the same packet id
	// sends automatically retry messages
	// returns EOK, if command was successfully send
	// returns command reply in _reply
	error_t  sendPacket(const gpb_packet_t& _packet);

	bool bootloader_startApp();

	// Sett communication timeout in ms
	void setTimeoutMs(int _timeOut)
	{
		m_timeout=_timeOut;
	}

	// sends test command
	// returns EOK, if test command reply was received successfully
	error_t testCmd();
	// sends command to Hamamatsu processor
	// returns EOK, if command was successfully send
	// returns command reply in _reply
	error_t  sendPmtCommand(std::string _command, std::string& _reply);

	// sends command to Hamamatsu processor
	// returns EOK, if command was successfully send
	// returns command reply in _reply
	error_t  pmt_getTemperature(int& _value);

	// sends set HV command to Hamamatsu processor
	// returns EOK, if command was successfully send
	error_t  pmt_setHV(double _voltage);

	// sends set HV on/off command to Hamamatsu processor
	// returns EOK, if command was successfully send
	error_t  pmt_power(bool _onoff);

	// set lgsel pin to high (1) or low (0)
	// returns EOK on success
	error_t  setLgSel(int _lgsel);

	// set rxlbsel pin to high (1) or low (0)
	// returns EOK on success
	error_t  setRxlbSel(int _value);

	// requests actual status of lgsel and rxlbsel
	// returns EOK on success and in _lgsel and _rxlbsel 1 = high and 0 = low status
	error_t  getStatus(bool& _lgsel, bool& _rxlbsel);

	// requests software version
	// returns EOK on success and
	// returns in version bit 15..8 major version and in bit 7..0 minor version
	error_t  getVersion(uint16_t& _version);

	// returns state
	state_t getState(void);

	// tries to initialize the panel, if it is in strange state
	bool initialize(bool _verbose);
};

GPBController& getGPBController(int _panel);


#endif /* ICESCINT_GPB_CLIENT_GPBCONTROLLER_HPP_ */
