/*
 * icescint_slowcontrolHandler.hpp
 *
 *  Created on: Oct 16, 2017
 *      Author: kossatz
 */

#ifndef SOURCE_DIRECTORY__TAXI_ICESCINT_ICESCINT_SLOWCONTROL_SERVER_ICESCINT_SLOWCONTROLHANDLER_HPP_
#define SOURCE_DIRECTORY__TAXI_ICESCINT_ICESCINT_SLOWCONTROL_SERVER_ICESCINT_SLOWCONTROLHANDLER_HPP_

#include "thriftSlowControl/gen-cpp/slowcontrol_types.h"
#include "thriftSlowControl/gen-cpp/icescint_slowcontrol.h"
#include <thrift/protocol/TBinaryProtocol.h>
#include <thrift/server/TSimpleServer.h>
#include <thrift/transport/TServerSocket.h>
#include <thrift/transport/TBufferTransports.h>

#define DUMMYVALUE 0xdead

class icescint_slowcontrolHandler: virtual public taxi::icescint_slowcontrolIf
{
public:
	icescint_slowcontrolHandler(bool _debug = false)
	{
		m_debug = _debug;
	}

	int16_t smcRead16(const int32_t address)
	{
		if (!m_debug)
		{
			return IORD_16DIRECT(address, 0);
		}
		else
		{
			std::cout << "smcRead16(" << int(address) << ")" << std::endl;
			return DUMMYVALUE;
		}
	}

	void smcWrite16(const int32_t address, const int16_t value)
	{
		if (!m_debug)
		{
			IOWR_16DIRECT(address, 0, value);
		}
		else
		{
			std::cout << "smcWrite16(" << int(address) << ", " << int(value) << ")" << std::endl;
		}
	}

	void sendFpgaConfig(const std::string& config)
	{
		if (!m_debug)
		{
			std::cout << "sendFpgaConfig not implemented" << std::endl;
		}
		else
		{
			std::cout << "sendFpgaConfig(...)" << std::endl;
		}
	}

	void setSipmHv(const int16_t channel, const double voltage)
	{
		if (!m_debug)
		{
			icescint_pannelSetSipmVoltage(channel, voltage, 10, 0);
		}
		else
		{
			std::cout << "setSipmHv(" << int(channel) << ", " << int(voltage) << ")" << std::endl;
		}
	}

	int16_t getSipmHv(const int16_t channel)
	{
		if (!m_debug)
		{
			std::cout << "setSipmPowerEnabled() not implemented" << std::endl;
			return DUMMYVALUE;
		}
		else
		{
			std::cout << "getSipmHv(" << int(channel) << ")" << std::endl;
			return DUMMYVALUE;
		}
	}

	void setSipmPowerEnabled(const int16_t channel, const bool enabled)
	{
		if (!m_debug)
		{
			std::cout << "setSipmPowerEnabled() not implemented" << std::endl;
		}
		else
		{
			std::cout << "setSipmPowerEnabled(" << int(channel) << ")" << std::endl;
		}
	}

	bool getSipmPowerEnabled(const int16_t channel)
	{
		if (!m_debug)
		{
			std::cout << "getSipmPowerEnabled() not implemented" << std::endl;
			return false;
		}
		else
		{
			std::cout << "getSipmPowerEnabled(" << int(channel) << ")" << std::endl;
			return DUMMYVALUE;
		}
	}

	void setTriggerThreshold(const int16_t channel, const int16_t treshold)
	{
		if (!m_debug)
		{
			icescint_setTriggerThreshold(channel, treshold);
		}
		else
		{
			std::cout << "setTriggerThreshold(" << int(channel) << ")" << std::endl;
		}
	}

	int16_t getTriggerTheshold(const int16_t channel)
	{
		if (!m_debug)
		{
			return icescint_getTriggerThreshold(channel);
		}
		else
		{
			std::cout << "getTriggerTheshold(" << int(channel) << ")" << std::endl;
			return DUMMYVALUE;
		}
	}

	void setNumberOfSamplesToRead(const int16_t value)
	{
		if (!m_debug)
		{
			icescint_setNumberOfSamplesToRead(value);
		}
		else
		{
			std::cout << "setNumberOfSamplesToRead(" << int(value) << ")" << std::endl;
		}
	}

	int16_t getNumberOfSamplesToRead(void)
	{
		if (!m_debug)
		{
			return icescint_getNumberOfSamplesToRead();
		}
		else
		{
			std::cout << "getNumberOfSamplesToRead()" << std::endl;
			return DUMMYVALUE;
		}
	}

	void setTriggerMask(const int16_t mask)
	{
		if (!m_debug)
		{
			icescint_setTriggerMask(mask);
		}
		else
		{
			std::cout << "setTriggerMask(" << int(mask) << ")" << std::endl;
		}
	}

	int16_t getTriggerMask(void)
	{
		if (!m_debug)
		{
			return icescint_getTriggerMask();
		}
		else
		{
			std::cout << "getTriggerMask()" << std::endl;
			return DUMMYVALUE;
		}
	}

	void setPixelTriggerCounterPeriod(const int16_t value)
	{
		if (!m_debug)
		{
			icescint_setPixelTriggerCounterPeriod(value);
		}
		else
		{
			std::cout << "setPixelTriggerCounterPeriod(" << int(value) << ")" << std::endl;
		}
	}

	int16_t getPixelTriggerCounterPeriod(const int16_t channel)
	{
		if (!m_debug)
		{
			return icescint_getPixelTriggerCounterPeriod();
		}
		else
		{
			std::cout << "getPixelTriggerCounterPeriod(" << int(channel) << ")" << std::endl;
			return DUMMYVALUE;
		}
	}

	int16_t getPixelTriggerCounterRate(const int16_t channel)
	{
		if (!m_debug)
		{
			return icescint_getPixelTriggerCounterRate(channel);
		}
		else
		{
			std::cout << "getPixelTriggerCounterRate(" << int(channel) << ")" << std::endl;
			return DUMMYVALUE;
		}
	}

	void setPacketConfig(const int16_t value)
	{
		if (!m_debug)
		{
			icescint_setEventFifoPacketConfig(value);
		}
		else
		{
			std::cout << "setPacketConfig(" << int(value) << ")" << std::endl;
		}
	}

	int16_t getPacketConfig(void)
	{
		if (!m_debug)
		{
			return icescint_getEventFifoPacketConfig();
		}
		else
		{
			std::cout << "getPacketConfig()" << std::endl;
			return DUMMYVALUE;
		}
	}

	void setReadoutMode(const int16_t value)
	{
		if (!m_debug)
		{
			icescint_setDrs4ReadoutMode(value);
		}
		else
		{
			std::cout << "setReadoutMode(" << int(value) << ")" << std::endl;
		}
	}

	int16_t getReadoutMode(void)
	{
		if (!m_debug)
		{
			return icescint_getDrs4ReadoutMode();
		}
		else
		{
			std::cout << "getReadoutMode()" << std::endl;
			return DUMMYVALUE;
		}
	}

private:
	bool m_debug;
}
;



#endif /* SOURCE_DIRECTORY__TAXI_ICESCINT_ICESCINT_SLOWCONTROL_SERVER_ICESCINT_SLOWCONTROLHANDLER_HPP_ */
