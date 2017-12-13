/*
 * Transport.hpp
 *
 *  Created on: 13 Dec 2017
 *      Author: marekp
 */

#ifndef LIBGBP_GPB_TRANSPORT_HPP_
#define LIBGBP_GPB_TRANSPORT_HPP_
#include <stdlib.h>

class IIOTransport
{
public:
	virtual ~IIOTransport()
	{}
	virtual void write(void* _data, size_t _size) = 0;
	virtual int read(void* _data, size_t _size) = 0;
};

#endif /* LIBGBP_GPB_TRANSPORT_HPP_ */
