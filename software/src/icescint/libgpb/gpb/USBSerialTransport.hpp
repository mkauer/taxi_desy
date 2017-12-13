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
	USBSerialTransport(const char* _device)
	{
		m_fd = open (_device, O_RDWR | O_NOCTTY | O_SYNC);
		if (m_fd < 0)
		{
		        std::cerr << "error " << errno << " : " << _device << " " << strerror(errno) << std::endl;
		        return ;
		}

		set_interface_attribs (m_fd, B9600, 0); // set speed to 115,200 bps, 8n1 (no parity)
	}
	~USBSerialTransport()
	{
		close(m_fd);
	}

	virtual void write(void* _data, size_t _size)
	{
		::write (m_fd, _data, _size); // send data
	}
	virtual int read(void* _data, size_t _size)
	{
		return ::read(m_fd, _data, _size);
	}
};

#endif /* LIBGBP_GPB_USBSERIALTRANSPORT_HPP_ */
