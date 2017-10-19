/*
 * NetworkStatistic.hpp
 *
 *  Created on: May 25, 2016
 *      Author: marekp
 */

#ifndef NETWORKSTATISTIC_HPP_
#define NETWORKSTATISTIC_HPP_

#include <stdint.h>
#include <string>
#include <sys/stat.h>
#include <stdio.h>
#include <fstream>

// Class for taking eth stats
class NetworkStatistic
{
	typedef struct {
		uint64_t rx_bytes;
		uint64_t tx_bytes;
		uint64_t rx_packets;
		uint64_t tx_packets;
		uint64_t rx_dropped;
		uint64_t tx_dropped;
		int collisions;
	} data_t;

	std::string	m_device;
	bool 	m_exist;
	data_t 	m_last;
	data_t 	m_actual;
	time_t  m_lastUpdate;
	time_t  m_actualUpdate;

	int64_t readInt64(const char* property);

public:

	// reset statistics and clean buffers
	void reset();

	NetworkStatistic()
	{
		setDevice("eth0");
	}

	NetworkStatistic(const std::string& _device)
	{
		setDevice(_device);
	}

	NetworkStatistic(int _deviceNumber)
	{
		char device[20];
		sprintf(device,"eth%d",_deviceNumber);
		setDevice(device);
	}

	// change device (also resets data)
	void setDevice(const std::string& _device)
	{
		if (m_device==_device) return;

		reset();
		m_device=_device;
		char buf[200];
		sprintf(buf, "/sys/class/net/%s",m_device.c_str());
		struct stat s = {0};
		m_exist = (!stat(buf, &s));
		update();
	}

	// returns true, if device node exists
	bool exists() const
	{
		return m_exist;
	}

	// updates all data
	void update();

	// generate getter
	//  *_diff    -> returns byte difference since last update
	//  *_total   -> returns total bytes since ifup
	//  *_per_sec -> returns bytes per sec if update period >=1 sec otherwise returns *_diff

#define __FUNC_DEF__(NAME) \
	int NAME##_diff() { return m_actual.NAME - m_last.NAME; } \
	uint64_t NAME##_total() { return m_actual.NAME; } \
	float NAME##_per_sec() { \
		int tdiff=m_actualUpdate-m_lastUpdate; \
		if (tdiff==0) return NAME##_diff(); \
		return NAME##_diff()/(float)tdiff; \
	}

	__FUNC_DEF__(rx_bytes);
	__FUNC_DEF__(tx_bytes);
	__FUNC_DEF__(rx_packets);
	__FUNC_DEF__(tx_packets);
	__FUNC_DEF__(collisions);
#undef __FUNC_DEF__

};

#endif /* NETWORKSTATISTIC_HPP_ */
