/*
 * USBSerialTransport.hpp
 *
 *  Created on: 13 Dec 2017
 *      Author: marekp
 */

#ifndef LIBGBP_GPB_TAXISERIALTRANSPORT_HPP_
#define LIBGBP_GPB_TAXISERIALTRANSPORT_HPP_

#include <fcntl.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <iostream>

#include "gpb/Transport.hpp"
#include "hal/icescint.h"

class TaxiSerialTransport : public IIOTransport
{
private:
	int m_panel;
public:
	TaxiSerialTransport(int _panel)
	: m_panel(_panel)
	{
		flush();
	}
	~TaxiSerialTransport()
	{
	}
	virtual void setSendEnable(bool _enable)
	{
		if (_enable) {
			icescint_doRs485SetTxEnable(1,m_panel);
		} else {
			icescint_doRs485SetTxEnable(0,m_panel);
		}
	}
	virtual void write(void* _data, size_t _size)
	{
		unsigned char* buf=(unsigned char*) _data;
		for (size_t i=0;i<_size;i++) {
			icescint_doRs485SendData(buf[i],m_panel);
		}
	}
	virtual int read(void* _data, size_t _size)
	{
		int count=0;
		unsigned char* buf=(unsigned char*) _data;
		size_t s=icescint_getRs485RxFifoCount(m_panel);
		while (s) {
			buf[count]=icescint_getRs485Data(m_panel);
			count++;
			if (count==_size) break;
			s--;
		}
		return count;
	}
	virtual void flush(void)
	{
		icescint_pannelFlushRxFifo(m_panel);
	}
	virtual void reboot(void)
	{
		icescint_setPanelPower(m_panel,0);
		sleep(1);
		icescint_setPanelPower(m_panel,1);
		sleep(1);
	}
};

#endif /* LIBGBP_GPB_TAXISERIALTRANSPORT_HPP_ */
