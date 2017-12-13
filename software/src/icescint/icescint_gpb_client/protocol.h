/*
 * protocol.h
 *
 *  Created on: 4 Jul 2017
 *      Author: marekp
 */

#ifndef GPB_PROGRAMMER_PROTOCOL_H_
#define GPB_PROGRAMMER_PROTOCOL_H_

typedef enum {
	MODE_PACKET_HEADER1,
	MODE_PACKET_HEADER2,
	MODE_PACKET_TYPE,
	MODE_PACKET_SIZE1,
	MODE_PACKET_SIZE2,
	MODE_PACKET_DATA,
	MODE_PACKET_IGNORE_DATA,
	MODE_PACKET_CRC,
	MODE_PACKET_TAIL1,
	MODE_PACKET_TAIL2,
} cmd_mode_t;

typedef enum {
	DECODER_ERROR_NONE=0,
	DECODER_ERROR_INVALID_HEADER=1,
	DECODER_ERROR_INVALID_TAIL1=2,
	DECODER_ERROR_INVALID_TAIL2=3,
	DECODER_ERROR_CHECKSUM=4,

} decoder_error_t;

#define PACKET_HEADER1 0xCA
#define PACKET_HEADER2 0xFE
#define PACKET_TAIL1   0xEF
#define PACKET_TAIL2   0xAC

typedef unsigned short packet_size_t;

typedef struct {
	// Packet data
	unsigned char  type;
	unsigned short size;
	packet_size_t  data_size;	// available size in data
	unsigned char* data;
	unsigned char  crc;
} packet_t;

// initializes a packet structure
void packet_init(packet_t* _packet, unsigned char _type, void* _data, packet_size_t _size)
{
	_packet->type=_type;
	_packet->size=_size;
	_packet->data_size=_size;
	_packet->data=static_cast<unsigned char*>(_data);
	_packet->crc=0;
}


typedef struct {
	cmd_mode_t 	   mode;
	packet_t* 	   packet;
	// housekeeping data
	unsigned short packet_wrpos;
	unsigned char  packet_valid;
	unsigned char  checksum;
	decoder_error_t error;

} packetDecoder_t;

void packetDecoder_init(packetDecoder_t* _decoder, packet_t* _packet)
{
	_decoder->mode=MODE_PACKET_HEADER1;
	_decoder->packet=_packet;
}

// returns 1, if a packet has been receive completely
// returns 0, otherwise
int packetDecoder_processData(packetDecoder_t* _decoder, unsigned char _data)
{
	_decoder->packet_valid=0;

//	std::cout << " 0x" << std::hex << ((int)_data);

	if (_decoder->mode!=MODE_PACKET_CRC) _decoder->checksum+=_data;

	int packetReady=0;
	_decoder->error=DECODER_ERROR_NONE;

	if (_decoder->mode==MODE_PACKET_HEADER1) {
		if (_data==PACKET_HEADER1) {
			_decoder->checksum=PACKET_HEADER1;
			_decoder->error=DECODER_ERROR_NONE;
			_decoder->mode=MODE_PACKET_HEADER2;
		} else {
			//std::cout << "decoder got bad char: " << ((int)_data) << std::endl;
		}
	}
	else if (_decoder->mode==MODE_PACKET_HEADER2) {
		if (_data==PACKET_HEADER1) {
			_decoder->checksum=PACKET_HEADER1;
			_decoder->error=DECODER_ERROR_NONE;
			_decoder->mode=MODE_PACKET_HEADER2;
		} else if (_data==PACKET_HEADER2) {
			_decoder->mode=MODE_PACKET_TYPE;
		} else {
			_decoder->error=DECODER_ERROR_INVALID_HEADER;
			_decoder->mode=MODE_PACKET_HEADER1;
		}
	}
	else if(_decoder->mode==MODE_PACKET_TYPE) {
		_decoder->packet->type=_data;
		_decoder->mode=MODE_PACKET_SIZE1;
	}
	else if(_decoder->mode==MODE_PACKET_SIZE1) {
		_decoder->packet->size=_data;
		_decoder->mode=MODE_PACKET_SIZE2;
	}
	else if(_decoder->mode==MODE_PACKET_SIZE2) {
		_decoder->packet->size|=(_data << 8);
		_decoder->packet_wrpos=0;
		_decoder->packet_valid=0;
		if (_decoder->packet->size==0) {
			_decoder->mode=MODE_PACKET_CRC;
		}
		else if (_decoder->packet->size<_decoder->packet->data_size) {
			_decoder->mode=MODE_PACKET_DATA;
		} else {
			_decoder->mode=MODE_PACKET_IGNORE_DATA;
		}
	}
	else if(_decoder->mode==MODE_PACKET_DATA) {
		_decoder->packet->data[_decoder->packet_wrpos]=_data;
		_decoder->packet_wrpos++;
		if (_decoder->packet_wrpos==_decoder->packet->size) {
			_decoder->mode=MODE_PACKET_CRC;
			_decoder->packet_valid=1;
		}
	}
	else if (_decoder->mode==MODE_PACKET_IGNORE_DATA) {
		_decoder->packet_wrpos++;
		if (_decoder->packet_wrpos==_decoder->packet->size) {
			_decoder->mode=MODE_PACKET_CRC;
		}
	}
	else if (_decoder->mode==MODE_PACKET_CRC) {
		// TBD: check crc
		if (_decoder->checksum!=_data) {
			// checksum error!
			_decoder->mode=MODE_PACKET_HEADER1;
			_decoder->error=DECODER_ERROR_CHECKSUM;
			std::cout << "Checksum error!" << std::endl;
		} else {
			_decoder->mode=MODE_PACKET_TAIL1;
		}
	}
	else if (_decoder->mode==MODE_PACKET_TAIL1) {
		if (_data==PACKET_TAIL1) {
			_decoder->mode=MODE_PACKET_TAIL2;
		} else {
			_decoder->mode=MODE_PACKET_HEADER1;
			// Packet Error
			_decoder->error=DECODER_ERROR_INVALID_TAIL1;
		}
	}
	else if (_decoder->mode==MODE_PACKET_TAIL2) {

		if (_data==PACKET_TAIL2) {
			packetReady=1;
			_decoder->mode=MODE_PACKET_HEADER1;
		} else {
			_decoder->mode=MODE_PACKET_HEADER1;
			// Packet Error
			_decoder->error=DECODER_ERROR_INVALID_TAIL2;
		}
	} else {
		_decoder->mode=MODE_PACKET_HEADER1;
	}

	if (_decoder->error) return -_decoder->error;
	return packetReady;
}

// serializes packet into a buffer with packet frame
int packet_serialize(packet_t*_packet, void* _buf, packet_size_t _bufsize)
{
	unsigned char* buf=static_cast<unsigned char*>(_buf);
	memset(buf,0,sizeof(buf));

	if (_bufsize<(_packet->size+7)) return -1; // error, buffer to small to fit packet + frame

	unsigned char checksum=0;

	buf[0]=0xca;
	buf[1]=0xfe;
	buf[2]=_packet->type;
	buf[3]=_packet->size & 0xff;
	buf[4]=((_packet->size >> 8) & 0xff);

	if (_packet->data) memcpy(&buf[5], _packet->data, _packet->size);

	for (int i=0;i<(_packet->size+5);i++) checksum+=buf[i];

	buf[5+_packet->size]=checksum;
	buf[6+_packet->size]=0xef;
	buf[7+_packet->size]=0xac;

	return _packet->size+8;
}

// serializes packet into a buffer with packet frame
int packet_write(packet_t*_packet, packet_size_t _pos, unsigned char _data)
{
	unsigned char* buf=static_cast<unsigned char*>(_packet->data);

	if (_pos > _packet->size-1) return 0; // packet to small, no byte written
	buf[_pos]=_data;

	return 1; // return success, 1 byte got written
}

// serializes packet into a buffer with packet frame
int packet_write_u16(packet_t*_packet, packet_size_t _pos, unsigned short _data)
{
	unsigned char* buf=static_cast<unsigned char*>(_packet->data);

	if (_pos>_packet->size-2) return 0; // packet to small, no byte written

	buf[_pos]=_data & 0xff;
	buf[_pos+1]=(_data >> 8) & 0xff;

	return 2; // return success, 2 byte got written
}

/*
void sendPacket(int fd, unsigned char _type,unsigned short _size, void* _data)
{
	unsigned char buf[1000];
	memset(buf,0,sizeof(buf));

	buf[0]=0xca;
	buf[1]=0xfe;
	buf[2]=_type;
	buf[3]=_size & 0xff;
	buf[4]=((_size >> 8) & 0xff);

	if (_data) memcpy(&buf[5],_data, _size);

	buf[5+_size]=0xef;
	buf[6+_size]=0xac;

	write (fd, buf, _size + 7); // send packet
}

void sendReadCmd(int fd, unsigned short _addr, unsigned short _length)
{
	unsigned char buf[10];
	memset(buf,0,sizeof(buf));

	buf[0]=_addr & 0xff;
	buf[1]=(_addr >> 8) & 0xff;
	buf[2]=_length & 0xff;
	buf[3]=(_length >> 8) & 0xff;

	sendPacket(fd,3,4,buf);
}



class Decoder
{
public:

	cmd_mode_t cmd_mode;
	#define CMD_BINARY_MAX_SIZE 120

	unsigned short cmd_binary_size;
	unsigned short cmd_binary_wrpos;
	unsigned char  cmd_binary_data[CMD_BINARY_MAX_SIZE];
	unsigned char  cmd_binary_data_valid;
	unsigned char  cmd_binary_type;

	Decoder()
	{
		cmd_mode=MODE_PACKET_HEADER1;
	}

	bool put(unsigned char ch)
	{
		int packetReady=0;
		int error=0;
		if (cmd_mode==MODE_PACKET_HEADER1) {
			if (ch==PACKET_HEADER1) {
				cmd_mode=MODE_PACKET_HEADER2;
			}
		}
		else if (cmd_mode==MODE_PACKET_HEADER2) {
			if (ch==PACKET_HEADER1) {
				cmd_mode=MODE_PACKET_HEADER2;
			} else if (ch==PACKET_HEADER2) {
				cmd_mode=MODE_PACKET_TYPE;
			} else {
				error=1;
			}
		}
		else if(cmd_mode==MODE_PACKET_TYPE) {
			cmd_binary_type=ch;
			cmd_mode=MODE_PACKET_SIZE1;
		}
		else if(cmd_mode==MODE_PACKET_SIZE1) {
			cmd_binary_size=ch;
			cmd_mode=MODE_PACKET_SIZE2;
		}
		else if(cmd_mode==MODE_PACKET_SIZE2) {
			cmd_binary_size|=(ch << 8);
			cmd_binary_wrpos=0;
			cmd_binary_data_valid=0;
			if (cmd_binary_size==0) {
				cmd_mode=MODE_PACKET_CRC;
			}
			else if (cmd_binary_size<CMD_BINARY_MAX_SIZE) {
				cmd_mode=MODE_PACKET_DATA;
			} else {
				cmd_mode=MODE_PACKET_IGNORE_DATA;
			}
		}
		else if(cmd_mode==MODE_PACKET_DATA) {
			cmd_binary_data[cmd_binary_wrpos]=ch;
			cmd_binary_wrpos++;
			if (cmd_binary_wrpos==cmd_binary_size) {
				cmd_mode=MODE_PACKET_CRC;
				cmd_binary_data_valid=1;
			}
		}
		else if (cmd_mode==MODE_PACKET_IGNORE_DATA) {
			cmd_binary_wrpos++;
			if (cmd_binary_wrpos==cmd_binary_size) {
				cmd_mode=MODE_PACKET_CRC;
			}
		}
		else if (cmd_mode==MODE_PACKET_CRC) {
			// TBD: check crc
			cmd_mode=MODE_PACKET_TAIL1;
		}
		else if (cmd_mode==MODE_PACKET_TAIL1) {
			if (ch==PACKET_TAIL1) {
				cmd_mode=MODE_PACKET_TAIL2;
			} else {
				cmd_mode=MODE_PACKET_HEADER1;
				// Packet Error
				error=1;
			}
		}
		else if (cmd_mode==MODE_PACKET_TAIL2) {

			if (ch==PACKET_TAIL2) {
				packetReady=1;
				cmd_mode=MODE_PACKET_HEADER1;
			} else {
				cmd_mode=MODE_PACKET_HEADER1;
				// Packet Error
				error=0;
			}
		} else {
			cmd_mode=MODE_PACKET_HEADER1;
		}

		return packetReady;

	}
};

*/

#endif /* SOURCE_DIRECTORY__TAXI_ICESCINT_GPB_PROGRAMMER_PROTOCOL_H_ */
