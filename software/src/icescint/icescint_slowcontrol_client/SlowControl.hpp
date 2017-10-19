/*
 * SlowControl.h
 *
 *  Created on: Oct 12, 2017
 *      Author: kossatz
 */

#ifndef SOURCE_DIRECTORY__TAXI_ICESCINT_ICESCINT_SLOWCONTROL_CLIENT_SLOWCONTROL_HPP_
#define SOURCE_DIRECTORY__TAXI_ICESCINT_ICESCINT_SLOWCONTROL_CLIENT_SLOWCONTROL_HPP_

//#include <glog/logging.h>
#include "ThriftAutoClient.hpp"
#include "thriftSlowControl/gen-cpp/icescint_slowcontrol.h"
#include "thriftSlowControl/gen-cpp/slowcontrol_types.h"

namespace taxi
{

typedef ThriftSimpleClient<icescint_slowcontrolClient> slowControlClient;

class SlowControl
{
public:
	virtual ~SlowControl();
	SlowControl(std::string _address, int _port);
//	SlowControl();

	bool bla();
	uint16_t smcRead16(const int32_t address);
	void smcWrite16(const int32_t address, const uint16_t value);
	void sendFpgaConfig(const std::string& config);
	void setSipmHv(const uint16_t channel, const double voltage);
	uint16_t getSipmHv(const uint16_t channel);
	void setSipmPowerEnabled(const uint16_t channel, const bool enabled);
	bool getSipmPowerEnabled(const uint16_t channel);
	void setTriggerThreshold(const uint16_t channel, const uint16_t treshold);
	uint16_t getTriggerTheshold(const uint16_t channel);
	void setNumberOfSamplesToRead(const uint16_t value);
	uint16_t getNumberOfSamplesToRead(void);
	void setTriggerMask(const uint16_t value);
	uint16_t getTriggerMask(void);
	void setPixelTriggerCounterPeriod(const uint16_t value);
	uint16_t getPixelTriggerCounterPeriod(const uint16_t channel);
	uint16_t getPixelTriggerCounterRate(const uint16_t channel);
	void setPacketConfig(const uint16_t value);
	uint16_t getPacketConfig(void);
	void setReadoutMode(const uint16_t value);
	uint16_t getReadoutMode(void);

private:
	slowControlClient m_client;
};



} // namespace taxi


#endif /* SOURCE_DIRECTORY__TAXI_ICESCINT_ICESCINT_SLOWCONTROL_CLIENT_SLOWCONTROL_HPP_ */
