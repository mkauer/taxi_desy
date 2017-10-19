#include "boost/date_time/posix_time/posix_time.hpp"
#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>

#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <iostream>
#include <sstream>
#include "protocol.h"
#include "hexfile.h"
#include <fstream>

#define  error_message(MSG...) (MSG)

int set_interface_attribs (int fd, int speed, int parity)
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

        /*
        tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;     // 8-bit chars
        // disable IGNBRK for mismatched speed tests; otherwise receive break
        // as \000 chars
        tty.c_iflag &= ~IGNBRK;         // disable break processing
        tty.c_lflag = 0;                // no signaling chars, no echo,
                                        // no canonical processing
        tty.c_oflag = 0;                // no remapping, no delays
        tty.c_cc[VMIN]  = 0;            // read doesn't block
        tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

        tty.c_iflag &= ~(IXON | IXOFF | IXANY); // shut off xon/xoff ctrl
//        tty.c_iflag |= (IXON | IXOFF | IXANY); // shut off xon/xoff ctrl

        tty.c_cflag |= (CLOCAL | CREAD);// ignore modem controls,
        tty.c_cflag &= ~(PARENB | PARODD); // shut off parity
        tty.c_cflag |= parity;
        tty.c_cflag &= ~CSTOPB;
        tty.c_cflag &= ~CRTSCTS;
        */

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
                error_message ("error %d from tcsetattr", errno);
                return -1;
        }
        return 0;
}

char nibbleToHex(char val) {
	if((val & 0xf) >= 0x0a) {
		return 'A' + (val-10);
	} else {
		return '0' + (val);
	}
}

char portname[] = "/dev/ttyUSB1";

bool testPmt(std::string _data)
{
	int fd = open (portname, O_RDWR | O_NOCTTY | O_SYNC);
	if (fd < 0)
	{
		error_message ("error %d opening %s: %s", errno, portname, strerror (errno));
		return false;
	}

	set_interface_attribs (fd, B38400, 0); // set speed to 115,200 bps, 8n1 (no parity)

	char buf[100];
	int len=strlen(_data.c_str());
	if (len>=52) {
		std::cout << "send: string must be < 52 bytes" << std::endl;
		return false;
	}
	unsigned char checksum=0x02;
	buf[0]=0x02; // STX
	for (int i=0;i<len;i++) {
		buf[1+i]=_data[i];
		checksum+=_data[i];
	}
	buf[len+1]=0x03; // STX
	checksum+=0x03;
	buf[len+2]=nibbleToHex((checksum >> 4));
	buf[len+3]=nibbleToHex((checksum & 0xf));
	buf[len+4]=0x0d;

	write(fd, buf,len+5);


}

int main(int argc, char** argv)
{
	using namespace std;
	cout << "***** icescint pmt test sender - " << __DATE__ << " " << __TIME__ << endl;

	testPmt("hELLO!");

/*	string filename;
 *

	unsigned int     mask;
	bool didSomething = false;
	po::options_description desc("Allowed options");
	desc.add_options()
			("help,h", "")
			("check,c", "check bootloader id")
		    ("filename,f", po::value<std::string>(&filename), "set .hex file to use")
			("write,w", "write hex file to flash")
			("verify,v", "verify hex file with flash")
			("test,t", "test communication")
			("start,s", "start application")
		;
	po::variables_map vm;
	try {
		po::store(
			po::command_line_parser(argc, argv).options(desc).allow_unregistered().run(),
		vm);
	} catch (boost::program_options::invalid_command_line_syntax &e) {
		cout << "error: " << e.what() << endl;
		return -1;
	}

	//po::store(po::command_line_parser(argc, argv).options(desc).positional(p).run(), vm);

	po::notify(vm);

	if (vm.count("help")) {
		cout << desc << "\n";
		return 0;
	}

*/

}
