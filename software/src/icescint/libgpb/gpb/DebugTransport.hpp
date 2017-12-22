/*
 * DebugTransport.hpp
 *
 *  Created on: Dec 14, 2017
 *      Author: marekp
 */

#ifndef SOURCE_DIRECTORY__SRC_ICESCINT_LIBGPB_GPB_DEBUGTRANSPORT_HPP_
#define SOURCE_DIRECTORY__SRC_ICESCINT_LIBGPB_GPB_DEBUGTRANSPORT_HPP_

#include "gpb/Transport.hpp"
#include <iostream>

class DebugTransport : public IIOTransport
{
private:
	IIOTransport* m_other;

public:
	DebugTransport(IIOTransport* _other)
	: m_other(_other) {}
	virtual void write(void* _data, size_t _size)
	{
		if (_size) {
			char* buf=(char*)_data;
			std::cout << "write: ";
			for (int i=0;i<_size;i++) std::cout << std::hex << " 0x" << (int)buf[i];
			std::cout << std::endl;
		}
		m_other->write ( _data, _size); // send data
	}
	virtual void setSendEnable(bool _enable)
	{
		m_other->setSendEnable(_enable);
	}
	virtual int read(void* _data, size_t _size)
	{
		size_t s=m_other->read( _data, _size);
		if (s>0) {
			char* buf=(char*)_data;
			std::cout << "read: ";
			for (int i=0;i<s;i++) std::cout << std::hex << " 0x" << (int)buf[i];
			std::cout << std::endl;
		}
		return s;
	}
	virtual void flush(void)
	{
		std::cout << "flush!" << std::endl;
		m_other->flush();
	}
	virtual void reboot(void)
	{
		std::cout << "reboot panel!" << std::endl;
		m_other->reboot();
	}

};

#endif /* SOURCE_DIRECTORY__SRC_ICESCINT_LIBGPB_GPB_DEBUGTRANSPORT_HPP_ */
