#include "SlowControl.hpp"
#include <iostream>

namespace taxi
{

#ifdef THRIFT_SAFE_BLOCK
#undef THRIFT_SAFE_BLOCK
#endif
#define THRIFT_SAFE_BLOCK( STUFF... ) try { STUFF } catch (TTransportException &e) \
		{ \
			std::ostringstream o;\
			o << __FUNCTION__ << " throws a transport exception: '" << e.what() << "'"; \
			std::cerr << o.str();\
		} catch (std::exception& e) \
		{ \
			std::ostringstream o;\
			o << __FUNCTION__ << " throws std::exception : '" << e.what() << "'"; \
			std::cerr << o.str();\
		}


SlowControl::~SlowControl()
{
	// TODO Auto-generated destructor stub
}

SlowControl::SlowControl(std::string _address, int _port) : m_client(_address,_port)
{

}

bool SlowControl::bla(void)
{
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
			return false;
		}
		else
		{
			m_client.interface().smcRead16(0);
		}
		return true;
	);
	return false;
}

uint16_t SlowControl::smcRead16(const int32_t address)
{
	int16_t ret = 0;
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			ret =m_client.interface().smcRead16(address);
		}
	);
	return ret;
}

void SlowControl::smcWrite16(const int32_t address, const uint16_t value)
{
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			m_client.interface().smcWrite16(address,value);
		}
	);
}

void SlowControl::sendFpgaConfig(const std::string& config)
{
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
//			m_client.interface().sendFpgaConfig(config);
			std::cerr << "error: not implemented";
		}
	);
}

void SlowControl::setSipmHv(const uint16_t channel, const double voltage)
{
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			m_client.interface().setSipmHv(channel, voltage);
		}
	);
}

uint16_t SlowControl::getSipmHv(const uint16_t channel)
{
	uint16_t ret = 0;
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			ret =m_client.interface().getSipmHv(channel);
		}
	);
	return ret;
}

void SlowControl::setSipmPowerEnabled(const uint16_t channel, const bool enabled)
{
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			m_client.interface().setSipmPowerEnabled(channel, enabled);
		}
	);
}

bool SlowControl::getSipmPowerEnabled(const uint16_t channel)
{
	bool ret = false;
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			ret =m_client.interface().getSipmPowerEnabled(channel);
		}
	);
	return ret;
}

void SlowControl::setTriggerThreshold(const uint16_t channel, const uint16_t treshold)
{
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			m_client.interface().setTriggerThreshold(channel,treshold);
		}
	);
}

uint16_t SlowControl::getTriggerTheshold(const uint16_t channel)
{
	uint16_t ret = 0;
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			ret =m_client.interface().getTriggerTheshold(channel);
		}
	);
	return ret;
}

void SlowControl::setNumberOfSamplesToRead(const uint16_t value)
{
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			m_client.interface().setNumberOfSamplesToRead(value);
		}
	);
}

uint16_t SlowControl::getNumberOfSamplesToRead(void)
{
	uint16_t ret = 0;
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			ret = m_client.interface().getNumberOfSamplesToRead();
		}
	);
	return ret;
}

void SlowControl::setTriggerMask(const uint16_t value)
{
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			m_client.interface().setTriggerMask(value);
		}
	);
}

uint16_t SlowControl::getTriggerMask(void)
{
	uint16_t ret = 0;
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			ret = m_client.interface().getTriggerMask();
		}
	);
	return ret;
}

void SlowControl::setPixelTriggerCounterPeriod(const uint16_t value)
{
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			m_client.interface().setPixelTriggerCounterPeriod( value);
		}
	);
}

uint16_t SlowControl::getPixelTriggerCounterPeriod(const uint16_t channel)
{
	uint16_t ret = 0;
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			ret = m_client.interface().getPixelTriggerCounterPeriod(channel);
		}
	);
	return ret;
}

uint16_t SlowControl::getPixelTriggerCounterRate(const uint16_t channel)
{
	uint16_t ret = 0;
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			ret =m_client.interface().getPixelTriggerCounterRate(channel);
		}
	);
	return ret;
}

void SlowControl::setPacketConfig(const uint16_t value)
{
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			m_client.interface().setPacketConfig(value);
		}
	);
}

uint16_t SlowControl::getPacketConfig(void)
{
	uint16_t ret = 0;
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			ret = m_client.interface().getPacketConfig();
		}
	);
	return ret;
}

void SlowControl::setReadoutMode(const uint16_t value)
{
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			m_client.interface().setReadoutMode(value);
		}
	);
}

uint16_t SlowControl::getReadoutMode(void)
{
	uint16_t ret = 0;
	THRIFT_SAFE_BLOCK
	(
		if (!m_client.isConnected())
		{
			std::cerr << "error message...";
		}
		else
		{
			ret = m_client.interface().getReadoutMode();
		}
	);
	return ret;
}


} // namespace taxi

