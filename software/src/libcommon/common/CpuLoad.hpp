/*
 * CpuStatistic.hpp
 *
 *  Created on: May 25, 2016
 *      Author: marekp
 */

#ifndef CPULOAD_HPP_
#define CPULOAD_HPP_

#include <fstream>
#include <string>

// class for measuring cpu load between with variable measurement periods
class CpuLoad
{
public:
	typedef struct {
		int jiffs_user; 	// normal processes executing in user mode
		int jiffs_nice; 	// normal processes executing in user mode
		int jiffs_system; 	// processes executing in kernel mode
		int jiffs_idle; 	// twiddling thumbs
		int jiffs_iowait;	// waiting for I/O to complete
		int jiffs_irq;		// servicing interrupts
		int jiffs_softirq;  // servicing softirqs
	} cpuUsage_t;

	cpuUsage_t m_last;
	cpuUsage_t m_actual;

    void update();

    CpuLoad()
    {
    	update();
    	m_last=m_actual;
    }

#define DIFF(NAME) int NAME() { return m_actual.jiffs_##NAME - m_last.jiffs_##NAME; }

    DIFF(user);
    DIFF(nice);
    DIFF(system);
    DIFF(idle);
    DIFF(iowait);
    DIFF(irq);
    DIFF(softirq);

#undef DIFF

    int total()
    {
    	return user() + nice() + system() + idle() + iowait() + irq() + softirq();
    }

    float totalCpuLoadPercentage()
    {
    	float t=total();
    	return (t-idle()-iowait())/(float)total();
    }

};


#endif /* CPUSTATISTIC_HPP_ */
