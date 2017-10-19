/*
 * icescint_decoder.hpp
 *
 *  Created on: Jul 19, 2017
 *      Author: marekp
 */

#ifndef ICESCINT_DECODER_HPP_
#define ICESCINT_DECODER_HPP_

#include <hal/icescint_defines.h>

// class to decode icescint event data
// it cannot
class IcescintDecoder
{
public:

	typedef struct {
		uint16_t header;
		uint16_t data[ICESCINT_FIFO_WIDTH_WORDS - 1];
	} eventdata_t;

private:
	typedef enum {
		PROCESS_HEADER,
		PROCESS_PAYLOAD,
	} state_t;

	state_t 	m_state;
	int 		m_dataWordCount;
	bool		m_validateHeader;
	eventdata_t m_eventData;

public:

	// optional parameter to activate header validation
	IcescintDecoder(bool _validateHeader=true)
	: m_validateHeader(_validateHeader)
	{
		reset();
	}

	// reset the decoder to wait for a header
	void reset()
	{
		m_state=PROCESS_HEADER;
		m_dataWordCount=0;
	}

	const eventdata_t& eventData() const
	{
		return m_eventData;
	}

	// returns true, if a known packet was detected
	bool processData(uint16_t _data)
	{
		if (m_state==PROCESS_HEADER) {
			if (m_validateHeader && !icescint_isValidHeader(_data)) {
				std::cerr << "icescint_decoder: invalid header detected 0x" << std::hex << _data << std::endl;
				return false;
			}
			m_eventData.header=_data;
			m_state=PROCESS_PAYLOAD;
			m_dataWordCount=0;
		} else if (m_state==PROCESS_PAYLOAD) {
			m_eventData.data[m_dataWordCount]=_data;
			m_dataWordCount++;
			if (m_dataWordCount==(ICESCINT_FIFO_WIDTH_WORDS - 1)) {
				m_state=PROCESS_HEADER;
				return true; // we got full eventdata
			}
		}
		return false;

	}

	// returns true, if a known packet was detected
	// returns new detected packet in parameter 2
	bool processData(uint16_t _data, eventdata_t& _eventData)
	{
		if (processData(_data)) {
			_eventData=m_eventData;
			return true;
		} else return false;
	}


};

#endif /* ICESCINT_DECODER_HPP_ */
