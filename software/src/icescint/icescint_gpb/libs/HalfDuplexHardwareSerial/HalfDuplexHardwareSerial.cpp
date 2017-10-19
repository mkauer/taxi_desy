/*
  HalfDuplexHardwareSerial.cpp - Hardware halfDuplexSerial library for Wiring
  Copyright (c) 2006 Nicholas Zambetti.  All right reserved.

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
  
  Modified 23 November 2006 by David A. Mellis
  Modified 28 September 2010 by Mark Sproul
  Modified 14 August 2012 by Alarus
  Modified 3 December 2013 by Matthijs Kooijman
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <inttypes.h>
#include "Arduino.h"

#include "HalfDuplexHardwareSerial.h"
#include "HalfDuplexHardwareSerial_private.h"

// this next line disables the entire HalfDuplexHardwareSerial.cpp, 
// this is so I can support Attiny series and any other chip without a uart
#if defined(HAVE_HWSERIAL0) || defined(HAVE_HWSERIAL1) || defined(HAVE_HWSERIAL2) || defined(HAVE_HWSERIAL3)

// HalfDuplexSerialEvent functions are weak, so when the user doesn't define them,
// the linker just sets their address to 0 (which is checked below).
// The HalfDuplexSerialx_available is just a wrapper around HalfDuplexSerialx.available(),
// but we can refer to it weakly so we don't pull in the entire
// HalfDuplexHardwareSerial instance if the user doesn't also refer to it.
#if defined(HAVE_HWSERIAL0)
  void halfDuplexSerialEvent() __attribute__((weak));
  bool HalfDuplexSerial0_available() __attribute__((weak));
#endif

#if defined(HAVE_HWSERIAL1)
  void halfDuplexSerialEvent1() __attribute__((weak));
  bool HalfDuplexSerial1_available() __attribute__((weak));
#endif

#if defined(HAVE_HWSERIAL2)
  void halfDuplexSerialEvent2() __attribute__((weak));
  bool HalfDuplexSerial2_available() __attribute__((weak));
#endif

#if defined(HAVE_HWSERIAL3)
  void halfDuplexSerialEvent3() __attribute__((weak));
  bool HalfDuplexSerial3_available() __attribute__((weak));
#endif

void halfDuplexSerialEventRun(void)
{
#if defined(HAVE_HWSERIAL0)
  if (HalfDuplexSerial0_available && halfDuplexSerialEvent && HalfDuplexSerial0_available()) halfDuplexSerialEvent();
#endif
#if defined(HAVE_HWSERIAL1)
  if (HalfDuplexSerial1_available && halfDuplexSerialEvent1 && HalfDuplexSerial1_available()) halfDuplexSerialEvent1();
#endif
#if defined(HAVE_HWSERIAL2)
  if (HalfDuplexSerial2_available && halfDuplexSerialEvent2 && HalfDuplexSerial2_available()) halfDuplexSerialEvent2();
#endif
#if defined(HAVE_HWSERIAL3)
  if (HalfDuplexSerial3_available && halfDuplexSerialEvent3 && HalfDuplexSerial3_available()) halfDuplexSerialEvent3();
#endif
}

#define PIN_RS485_DE _BV(4) // PORT E, PE4

static volatile bool isWriteMode=false;

void HalfDuplexHardwareSerial::rs485_write(bool write_en)
{
	int old=_writeModeEnabled;
	int newMode=_writeModeEnabled;

	if (write_en) newMode++; else newMode--;

	if (newMode<0) {
		Serial1.write("_writeModeEnabled<0!\r\n");
		_writeModeEnabled=0;
		return;
	}

	DDRE|=PIN_RS485_DE; // activate output control pin

	if ((old==0 && newMode==1)) {
   // 	DDRD|=_BV(0);  // LED, disturbs analog signal!
   // 	PORTD|=_BV(0);

		_writeModeEnabled=1;

    	// disable receiver, enable transmitter
    	PORTE=PORTE | PIN_RS485_DE;
		cbi(*_ucsrb, RXEN0);
		sbi(*_ucsrb, TXEN0);

     	delay(2);

	} else if (old==1 && newMode==0) {
    	flush();
       	delay(2);

  //  	DDRD|=_BV(0); // LED, disturbs analog signal!
  //  	PORTD&=~_BV(0);

		if (bit_is_clear(*_ucsra, TXC0)) {
			Serial1.write("ERROR! ");
		}
		_writeModeEnabled=0;

	    // enable receiver, disable transmitter
		sbi(*_ucsrb, RXEN0);
		cbi(*_ucsrb, TXEN0);
      	PORTE=PORTE & (~PIN_RS485_DE);
	} else {
		// do nothing
		_writeModeEnabled=newMode;
	}


}

void HalfDuplexHardwareSerial::beginWrite()
{
	rs485_write(true);
}
void HalfDuplexHardwareSerial::endWrite()
{
	rs485_write(false);
}


// Actual interrupt handlers //////////////////////////////////////////////////////////////

static volatile bool txIrqIsActive=false;

int HalfDuplexHardwareSerial::writeNext(void)
{
  if (_tx_buffer_head != _tx_buffer_tail) {
	  unsigned char c = _tx_buffer[_tx_buffer_tail];
	  _tx_buffer_tail = (_tx_buffer_tail + 1) % SERIAL_TX_BUFFER_SIZE;

	  *_udr = c;
	  //Serial1.write(c);

	  sbi(*_ucsra, TXC0);
	  sbi(*_ucsrb, UDRIE0); // enable data register empty irq
	  return 1;
  } else {
	  cbi(*_ucsrb, UDRIE0); // disable data register empty irq
	  return -1;
  }
}

void HalfDuplexHardwareSerial::_tx_udr_empty_irq(void)
{
  writeNext();
}

void HalfDuplexHardwareSerial::_tx_complete_irq(void)
{
	Serial1.write("tx complete");
	//sbi(*_ucsra, TXC0);
}


// Public Methods //////////////////////////////////////////////////////////////

void HalfDuplexHardwareSerial::begin(unsigned long baud, byte config)
{
  // Try u2x mode first
  uint16_t baud_setting = (F_CPU / 4 / baud - 1) / 2;
  *_ucsra = 1 << U2X0;

  // hardcoded exception for 57600 for compatibility with the bootloader
  // shipped with the Duemilanove and previous boards and the firmware
  // on the 8U2 on the Uno and Mega 2560. Also, The baud_setting cannot
  // be > 4095, so switch back to non-u2x mode if the baud rate is too
  // low.
  if (((F_CPU == 16000000UL) && (baud == 57600)) || (baud_setting >4095))
  {
    *_ucsra = 0;
    baud_setting = (F_CPU / 8 / baud - 1) / 2;
  }

  // assign the baud_setting, a.k.a. ubrr (USART Baud Rate Register)
  *_ubrrh = baud_setting >> 8;
  *_ubrrl = baud_setting;

  _written = false;

  //set the data bits, parity, and stop bits
#if defined(__AVR_ATmega8__)
  config |= 0x80; // select UCSRC register (shared with UBRRH)
#endif
  *_ucsrc = config;
 
  DDRE=DDRE | PIN_RS485_DE; // activate WRITE enable output pin

  // toggle to get into defined state and start in read state

  rs485_write(true);
  rs485_write(false);

  sbi(*_ucsrb, RXEN0);
  cbi(*_ucsrb, TXEN0);
  
  sbi(*_ucsrb, RXCIE0);
  cbi(*_ucsrb, UDRIE0);
  // sbi(*_ucsrb, TXCIE0);

  _writeModeEnabled=0;
}

void HalfDuplexHardwareSerial::end()
{
  // wait for transmission of outgoing data
  while (_tx_buffer_head != _tx_buffer_tail)
    ;

  cbi(*_ucsrb, RXEN0);
  cbi(*_ucsrb, TXEN0);
  cbi(*_ucsrb, RXCIE0);
  cbi(*_ucsrb, UDRIE0);
  
  // clear any received data
  _rx_buffer_head = _rx_buffer_tail;
}

int HalfDuplexHardwareSerial::available(void)
{
  return ((unsigned int)(SERIAL_RX_BUFFER_SIZE + _rx_buffer_head - _rx_buffer_tail)) % SERIAL_RX_BUFFER_SIZE;
}

int HalfDuplexHardwareSerial::peek(void)
{
  if (_rx_buffer_head == _rx_buffer_tail) {
    return -1;
  } else {
    return _rx_buffer[_rx_buffer_tail];
  }
}

int HalfDuplexHardwareSerial::read(void)
{
  // if the head isn't ahead of the tail, we don't have any characters
  if (_rx_buffer_head == _rx_buffer_tail) {
    return -1;
  } else {
    unsigned char c = _rx_buffer[_rx_buffer_tail];
    _rx_buffer_tail = (rx_buffer_index_t)(_rx_buffer_tail + 1) % SERIAL_RX_BUFFER_SIZE;
    return c;
  }
}

int HalfDuplexHardwareSerial::availableForWrite(void)
{
#if (SERIAL_TX_BUFFER_SIZE>256)
  uint8_t oldSREG = SREG;
  cli();
#endif
  tx_buffer_index_t head = _tx_buffer_head;
  tx_buffer_index_t tail = _tx_buffer_tail;
#if (SERIAL_TX_BUFFER_SIZE>256)
  SREG = oldSREG;
#endif
  if (head >= tail) return SERIAL_TX_BUFFER_SIZE - 1 - head + tail;
  return tail - head - 1;
}

void HalfDuplexHardwareSerial::flush()
{
	if (!_writeModeEnabled) {
		Serial1.write("cannot write!");
		return;
	}

	// If we have never written a byte, no need to flush. This special
	// case is needed since there is no way to force the TXC (transmit
	// complete) bit to 1 during initialization
	if (!_written)
		return;

	while ((_tx_buffer_head != _tx_buffer_tail)) {

	  if (bit_is_clear(SREG, SREG_I) && bit_is_set(*_ucsrb, UDRIE0)) {
		// Interrupts are globally disabled, but the DR empty
		// interrupt should be enabled, so poll the DR empty flag to
		// prevent deadlock
		if (bit_is_set(*_ucsra, UDRE0)) {
			writeNext();
			Serial1.write("flush wait1");
		}
	  }
	}

	while (bit_is_set(*_ucsrb, UDRIE0) ||
		 bit_is_clear(*_ucsra, TXC0) ||
		 bit_is_clear(*_ucsra, UDRE0)) {

	  //Serial1.write("flush wait2");
	  if (bit_is_clear(SREG, SREG_I) && bit_is_set(*_ucsrb, UDRIE0))
		// Interrupts are globally disabled, but the DR empty
		// interrupt should be enabled, so poll the DR empty flag to
		// prevent deadlock
		if (bit_is_set(*_ucsra, UDRE0)) {
		   writeNext();
			Serial1.write("flush wait2");

		}
	}

	while (bit_is_set(*_ucsrb, UDRIE0) ||
		 bit_is_clear(*_ucsra, TXC0)) {
		Serial1.write("flush wait 333");

	}
}

size_t HalfDuplexHardwareSerial::write(uint8_t c)
{
	if (!_writeModeEnabled) {
		Serial1.write("cannot write!");
		return 0;
	}

	tx_buffer_index_t i = (_tx_buffer_head + 1) % SERIAL_TX_BUFFER_SIZE;

	  // If the output buffer is full, there's nothing for it other than to
	  // wait for the interrupt handler to empty it a bit
	  while (i == _tx_buffer_tail) {
		  //Serial1.write("tx fifo full\r\n");
		if (bit_is_clear(SREG, SREG_I)) {
		  // Interrupts are disabled, so we'll have to poll the data
		  // register empty flag ourselves. If it is set, pretend an
		  // interrupt has happened and call the handler to free up
		  // space for us.
		  if(bit_is_set(*_ucsra, UDRE0))
			 writeNext();
		} else {
		  // nop, the interrupt handler will free up space for us
		}
	  }

	// add character to buffer
	_tx_buffer[_tx_buffer_head] = c;
	_tx_buffer_head = i;

	if (bit_is_clear(*_ucsrb, UDRIE0)) {
		writeNext();
	}

	_written = true;
  
	return 1;
}


#endif // whole file
