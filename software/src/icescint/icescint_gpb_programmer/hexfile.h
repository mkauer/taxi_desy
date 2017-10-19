/*
 * hexfile.h
 *
 *  Created on: 4 Jul 2017
 *      Author: marekp
 */

#ifndef HEXFILE_H_
#define HEXFILE_H_

#include <sstream>

// converts a ascii byte representated hex nibble (0..9 , a..f or A..F) into a integer 0..15
// on success returns integere 0..15
// on error returns -1
static inline char gethexnib(char a) {
	a=tolower(a);
	if(a >= 'a' && a<='f') {
		return (a - 'a' + 0x0a);
	} else if(a >= '0' && a <='9') {
		return(a - '0');
	}
	return -1;
}

// helper, reads two hex nibbles from a input stream and convert them into a byte
// returns true on success
// returns false on error
static inline bool readHexByte(std::istream& _in, unsigned char& _byte)
{
	char a,b;
	_in >> a >> b;
	a=gethexnib(a);
	b=gethexnib(b);
	if (a<0 || b<0) return false; // error decoding hex nibbles

	_byte=(a << 4) | b;
	return true;
}

typedef struct {
	int length;
	unsigned short addr;
	int type;
	unsigned char data[256];
	unsigned char checksum;
	unsigned char checksum_computed;
} hex_data_t;

static inline bool processHexFileLine(const std::string& _line, hex_data_t& _hexdata)
{
	std::stringstream s(_line);
	char a;
	unsigned char data;
	s >> a;

	if (a!=':') return false; // decoding error

	_hexdata.checksum_computed=0;

	if (readHexByte(s, data)<0) return false; // decoding error
	_hexdata.length=data;
	_hexdata.checksum_computed-=data;

	if (readHexByte(s, data)<0) return false; // decoding error
	_hexdata.addr=data << 8;
	_hexdata.checksum_computed-=data;

	if (readHexByte(s, data)<0) return false; // decoding error
	_hexdata.addr|=data;
	_hexdata.checksum_computed-=data;

	if (readHexByte(s, data)<0) return false; // decoding error
	_hexdata.type=data;
	_hexdata.checksum_computed-=data;

	for (int i=0;i<_hexdata.length;i++) {
		if (readHexByte(s, data)<0) return false; // decoding error
		_hexdata.data[i]=data;
		_hexdata.checksum_computed-=data;
	}

	if (readHexByte(s, data)<0) return false; // decoding error
	_hexdata.checksum=data;

	return true;
}


#endif /* SOURCE_DIRECTORY__TAXI_ICESCINT_GPB_PROGRAMMER_HEXFILE_H_ */
