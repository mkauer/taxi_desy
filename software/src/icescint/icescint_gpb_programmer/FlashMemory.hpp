/*
 * FlashMemory.hpp
 *
 *  Created on: 13 Dec 2017
 *      Author: marekp
 */

#ifndef SOURCE_DIRECTORY__SRC_ICESCINT_ICESCINT_GPB_PROGRAMMER2_FLASHMEMORY_HPP_
#define SOURCE_DIRECTORY__SRC_ICESCINT_ICESCINT_GPB_PROGRAMMER2_FLASHMEMORY_HPP_
#include <stdlib.h>
#include <string.h>

class FlashMemory
{
public:
	unsigned char* buf;
	unsigned char* used;
	size_t bufSize;

	FlashMemory()
	{
		bufSize=128*1024;
		buf=reinterpret_cast<unsigned char*>(malloc(bufSize));
		used=reinterpret_cast<unsigned char*>(malloc(bufSize));
		memset(buf,0xff,bufSize);
		memset(used,0,bufSize);
	}
	~FlashMemory()
	{
		free(buf);
		free(used);
	}
	void clear()
	{
		memset(buf,0xff,bufSize);
		memset(used,0,bufSize);
	}
	void put(size_t _addr, void* _data, size_t _size)
	{
		if (_addr+_size>=bufSize) return; // error buffer overflow!
		unsigned char* p=&reinterpret_cast<unsigned char*>(buf)[_addr];
		unsigned char* u=&reinterpret_cast<unsigned char*>(used)[_addr];
		memcpy(p, _data, _size);
		memset(u, 1, _size);
	}

	// returns number of continues allocated bytes starting with _addr
	// but not more than _maxSize
	bool getNextBlock(size_t& _addr)
	{
		size_t addr=_addr;
		if (addr>=bufSize) return false; // error buffer overflow!
		for (int i=addr;i<bufSize;i++) {
			if (used[i]) {
				_addr=i;
				return true; // found
			}
		}
		return false; // none found
	}

	// returns number of continues allocated bytes starting with _addr
	// but not more than _maxSize
	size_t getContinuesBlockSize(size_t _addr, size_t _maxSize)
	{
		if (_addr>=bufSize) return 0; // error buffer overflow!
		size_t s=0;
		for (int i=_addr;i<bufSize;i++) {
			if (!used[i]) break;
			s++;
			if (s>=_maxSize) break;
		}
		return s;
	}

	// copies _size from data buffer
	// returns number of bytes copied
	size_t getContinuesBlock(size_t& _addr, void* _data, size_t _size)
	{
		if (_addr>=bufSize) return 0; // error buffer overflow!
		if (_addr+_size>=bufSize) { // truncate
			_size=bufSize-_addr;
		}

		// try to find next block of used data
		if (!getNextBlock(_addr)) {
			//std::cout << "no next block found!" <<std::endl;
			return 0; // none found, exit
		} else {
			//std::cout << "using addr : 0x" << std::hex << _addr <<std::endl;
		}

		// check size of bytes available for usage
		_size=getContinuesBlockSize(_addr, _size);
		if (!_size) {
			//std::cout << "no continues block found!" <<std::endl;
			return 0; // nothing to copy found
		}

		unsigned char* p=&(reinterpret_cast<unsigned char*>(buf))[_addr];
		memcpy(_data, p, _size);
		return _size;
	}

};

#endif /* SOURCE_DIRECTORY__SRC_ICESCINT_ICESCINT_GPB_PROGRAMMER2_FLASHMEMORY_HPP_ */
