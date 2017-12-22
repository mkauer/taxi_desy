/*
 * pmt_decoder.h
 *
 *  Created on: Dec 18, 2017
 *      Author: marekp
 */

#ifndef ICESCINT_ICESCINT_GPB_PMT_DECODER_H_
#define ICESCINT_ICESCINT_GPB_PMT_DECODER_H_

// decoder modes
typedef enum {
	PMT_DECODER_MODE_STX,
	PMT_DECODER_MODE_DATA,
	PMT_DECODER_MODE_IGNORE_DATA,
	PMT_DECODER_MODE_CHECKSUM1,
	PMT_DECODER_MODE_CHECKSUM2,
	PMT_DECODER_MODE_DELIM,
} pmt_decoder_mode_t;

// pmt packet structure
typedef struct {
	char data[52];
	char data_pos;
	char data_len;
	char checksum;
	char checksum_received;
	pmt_decoder_mode_t mode;
} pmt_decoder_t;

void pmt_decoder_init(pmt_decoder_t* _decoder)
{
	_decoder->mode=PMT_DECODER_MODE_STX;
}

// decode state machine
char pmt_decoder_process(pmt_decoder_t* _decoder, char _data)
{
	char packetReady=0;
	if (_data==0x02) {
		_decoder->mode=PMT_DECODER_MODE_DATA;
		_decoder->data_pos=0;
		_decoder->checksum=_data;
	} else {
		if (_decoder->mode==PMT_DECODER_MODE_DATA) {
			_decoder->checksum+=_data;
			if (_data==0x03) {
				_decoder->data_len=_decoder->data_pos;
				_decoder->mode=PMT_DECODER_MODE_CHECKSUM1;
			} else {
				_decoder->data[uint8_t(_decoder->data_pos)]=_data;
				_decoder->data_pos++;
				if (_decoder->data_pos>=sizeof(_decoder->data)-1) {
					// error, to much data
					_decoder->mode=PMT_DECODER_MODE_IGNORE_DATA;
					_decoder->data_len=_decoder->data_pos;
				}
			}
		} else if (_decoder->mode==PMT_DECODER_MODE_IGNORE_DATA) {
			_decoder->checksum+=_data;
			// ignore all further data
			if (_data==0x03) {
				_decoder->mode=PMT_DECODER_MODE_CHECKSUM1;
			}
		} else if (_decoder->mode==PMT_DECODER_MODE_CHECKSUM1) {
			_decoder->checksum_received=gethexnib(_data) << 4;
			_decoder->mode=PMT_DECODER_MODE_CHECKSUM2;
		} else if (_decoder->mode==PMT_DECODER_MODE_CHECKSUM2) {
			_decoder->checksum_received|=gethexnib(_data);
			_decoder->mode=PMT_DECODER_MODE_DELIM;
		} else if (_decoder->mode==PMT_DECODER_MODE_DELIM) {
			packetReady=1;
			if (_data==0x0d) {
				_decoder->mode=PMT_DECODER_MODE_STX;
				packetReady=1;
			} else {
				_decoder->mode=PMT_DECODER_MODE_STX;
			}
		}

	}

	return packetReady;
}


#endif /* SOURCE_DIRECTORY__SRC_ICESCINT_ICESCINT_GPB_PMT_DECODER_H_ */
