/*
 * USBSerialTransport.hpp
 *
 *  Created on: 13 Dec 2017
 *      Author: marekp
 */

#ifndef LIBGBP_GPB_USBSERIALTRANSPORT_HPP_
#define LIBGBP_GPB_USBSERIALTRANSPORT_HPP_

#include <fcntl.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <iostream>

#include "Transport.hpp"

class USBSerialTransport : public IIOTransport
{
private:
	int m_fd;

	int set_interface_attribs (int fd, int speed, int parity);

	void set_blocking (int fd, int should_block);

public:
	USBSerialTransport(const char* _device);
	~USBSerialTransport()
	{
		close(m_fd);
	}
	virtual void setSendEnable(bool _enable)
	{
		// not needed, rs485 usb adapter does it magically automatically
	}
	virtual void write(void* _data, size_t _size)
	{
		::write (m_fd, _data, _size); // send data
	}
	virtual int read(void* _data, size_t _size)
	{
		return ::read(m_fd, _data, _size);
	}
	virtual void flush(void)
	{}
	virtual void reboot(void)
	{}
};

#endif /* LIBGBP_GPB_USBSERIALTRANSPORT_HPP_ */
