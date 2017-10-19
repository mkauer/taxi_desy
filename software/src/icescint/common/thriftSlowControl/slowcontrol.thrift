// **********************************************************************
// * Test pulse generator Slow Control interface
// **********************************************************************
namespace cpp taxi

service icescint_slowcontrol {

	// smc bus interface, for debugging	
	i16 smcRead16(1: i32 address)
	void smcWrite16(1: i32 address, 2: i16 value)
	
	// icescint hardware interface	
//	void doSingleSoftTrigger()
		
//	void setIrqEventCountThreshold(1: i32 value)
//	i32 getIrqEventCountThreshold()
		
	void sendFpgaConfig(1: string config)
	
	void setSipmHv(1: i16 channel, 2: double voltage)
	i16 getSipmHv(1: i16 channel)
	
	void setSipmPowerEnabled(1: i16 channel, 2: bool enabled)
	bool getSipmPowerEnabled(1: i16 channel)
	
	void setTriggerThreshold(1: i16 channel, 2: i16 treshold)
	i16 getTriggerTheshold(1: i16 channel)
	
	void setNumberOfSamplesToRead(1: i16 value)
	i16 getNumberOfSamplesToRead()
	
	void setTriggerMask(1: i16 value)
	i16 getTriggerMask()
	
	void setPixelTriggerCounterPeriod(1: i16 value)
	i16 getPixelTriggerCounterPeriod(1: i16 channel)
	
	i16 getPixelTriggerCounterRate(1: i16 channel)
	
	void setPacketConfig(1: i16 value)
	i16 getPacketConfig()
	
	void setReadoutMode(1: i16 value)
	i16 getReadoutMode()
		
}

