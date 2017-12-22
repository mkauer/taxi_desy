/*
 * USBSerialTransport.cpp
 *
 *  Created on: 13 Dec 2017
 *      Author: marekp
 */

#include "USBSerialTransport.hpp"

#include <errno.h>
#include <string.h>
#include <termios.h>
#include <iostream>

USBSerialTransport::USBSerialTransport(const char* _device)
{
	m_fd = open (_device, O_RDWR | O_NOCTTY | O_SYNC);
	if (m_fd < 0)
	{
			std::cerr << "error " << errno << " : " << _device << " " << strerror(errno) << std::endl;
			return ;
	}

	set_interface_attribs (m_fd, B9600, 0); // set speed to 115,200 bps, 8n1 (no parity)
}


int USBSerialTransport::set_interface_attribs (int fd, int speed, int parity)
{
	struct termios tty;
	memset (&tty, 0, sizeof tty);
	if (tcgetattr (fd, &tty) != 0)
	{

			std::cerr << "error " << errno << " from tcgetattr" << std::endl;
			return -1;
	}

	cfsetospeed (&tty, speed);
	cfsetispeed (&tty, speed);

	tty.c_iflag = 0;

	/* output modes - clear giving: no post processing such as NL to CR+NL */
	tty.c_oflag &= ~(OPOST|OLCUC|ONLCR|OCRNL|ONLRET|OFDEL);

	/* control modes - set 8 bit chars */
	tty.c_cflag |= ( CS8 ) ;

	/* local modes - clear giving: echoing off, canonical off (no erase with
	backspace, ^U,...), no extended functions, no signal chars (^Z,^C) */
	tty.c_lflag &= ~(ECHO | ECHOE | ICANON | IEXTEN | ISIG);


	if (tcsetattr (fd, TCSANOW, &tty) != 0)
	{
			std::cerr << "error " << errno << " from tcsetattr " << std::endl;
			return -1;
	}
	return 0;
}

void USBSerialTransport::set_blocking (int fd, int should_block)
{
	struct termios tty;
	memset (&tty, 0, sizeof tty);
	if (tcgetattr (fd, &tty) != 0)
	{
		std::cerr << "error " << errno << " from tggetattr" << std::endl;
		return;
	}

	tty.c_cc[VMIN]  = should_block ? 1 : 0;
	tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

	if (tcsetattr (fd, TCSANOW, &tty) != 0) {
		std::cerr << "error " << errno << " setting term attributes" << std::endl;
	}
}

