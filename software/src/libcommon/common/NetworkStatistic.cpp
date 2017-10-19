/*
 * NetworkStatistic.cpp
 *
 *  Created on: May 25, 2016
 *      Author: marekp
 */

#include "NetworkStatistic.hpp"
#include <stdio.h>
#include <sys/stat.h>
#include <fstream>
#include <string.h>

void NetworkStatistic::reset()
{
	memset(&m_actual,0,sizeof(m_actual));
	memset(&m_last,0,sizeof(m_last));
	update();
	m_last=m_actual;
	m_lastUpdate=m_actualUpdate;
}

int64_t NetworkStatistic::readInt64(const char* property)
{
	char buf[200];
	sprintf(buf, "/sys/class/net/%s/statistics/%s",m_device.c_str(), property);
	std::ifstream in(buf);
	//if (!in.isopen()) return 0;
	int64_t value;
	in >> value;
	return value;
}

void NetworkStatistic::update()
{
	if (!exists()) return;
	m_last=m_actual;
	m_lastUpdate=m_actualUpdate;
	m_actual.rx_bytes=readInt64("rx_bytes");
	m_actual.tx_bytes=readInt64("tx_bytes");
	m_actual.rx_packets=readInt64("rx_packets");
	m_actual.tx_packets=readInt64("tx_packets");
	m_actual.collisions=readInt64("collisions");
	m_actualUpdate = time(NULL);
}
