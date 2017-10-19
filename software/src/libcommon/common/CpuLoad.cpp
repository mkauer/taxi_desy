/*
 * CpuStatistic.cpp
 *
 *  Created on: May 25, 2016
 *      Author: marekp
 */

#include "CpuLoad.hpp"
#include <fstream>

void CpuLoad::update()
{
	m_last=m_actual;
	cpuUsage_t& _usage=m_actual;

	std::ifstream in("/proc/stat");
	std::string cpulabel;
	in >> cpulabel;
	in >> _usage.jiffs_user >> _usage.jiffs_nice >> _usage.jiffs_system;
	in >> _usage.jiffs_idle >> _usage.jiffs_iowait >> _usage.jiffs_irq;
	in >> _usage.jiffs_softirq;
}




