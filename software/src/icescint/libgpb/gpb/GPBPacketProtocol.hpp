/*
 * GPBPacketProtocol.hpp
 *
 *  Created on: 13 Dec 2017
 *      Author: marekp
 */

#ifndef ICESCINT_GPB_CLIENT_GPBPACKETPROTOCOL_HPP_
#define ICESCINT_GPB_CLIENT_GPBPACKETPROTOCOL_HPP_

#include "gpb_protocol.h"

class GPBPacketProtocol
{
private:
	IIOTransport* m_transport;
	packetDecoder_t m_decoder;
	gpb_packet_t m_packet;
	void* 	 m_packet_data;
	size_t 	 m_packet_data_size;

public:
	GPBPacketProtocol(IIOTransport* _transport, size_t _bufferSize=1000)
	: m_transport(_transport)
	{
		m_packet_data=malloc(_bufferSize);
		m_packet_data_size=_bufferSize;
		gpb_packet_init(&m_packet, 0, m_packet_data, m_packet_data_size);
		gpb_packetDecoder_init(&m_decoder, &m_packet);
	}
	~GPBPacketProtocol()
	{
		free(m_packet_data);
	}

	// Sends packet to file descriptor
	int sendPacket(gpb_packet_t* _packet)
	{
		unsigned char buf[1000];
		int size=gpb_packet_serialize(_packet, buf, sizeof(buf));
		if (size<0) return -1; // error

		m_transport->write (buf, size); // send packet
		return size;
	}

	// Sends packet to file descriptor
	// returns 1 if packet was received
	// returns 0 on timeout
	int receivePacket(int _timeout)
	{
		boost::posix_time::ptime timeoutTime=boost::posix_time::microsec_clock::local_time()+boost::posix_time::milliseconds(_timeout);

		bool checksumError=false;

		while(timeoutTime>boost::posix_time::microsec_clock::local_time()) {
			unsigned char buf [1000];
			int n = m_transport->read(buf, sizeof buf);  	// read up to 100 characters if ready

			for (int i=0;i<n;i++) {
				//std::cout << std::hex << " 0x" << ((int)buf[i]);
				int error=gpb_packetDecoder_processData(&m_decoder, buf[i]);
				if (error==1) {
					return 1; // packet received!
				}
			}
		}

		return 0; // timeout appeared
	}

	const gpb_packet_t& receivedPacket() const
	{
		return m_packet;
	}
};




#endif /* ICESCINT_GPB_CLIENT_GPBPACKETPROTOCOL_HPP_ */
