/*
 * FuseBits Settings:
 *
 *   LOW: 	0xAF
 *   HIGH:	0x88
 * 	 EXT:	0xFF
 *
 * 	 - M103C	- off
 * 	 - WDTON	- off
 * 	 - OCDEN	- off
 * 	 - JTAGEN	- on
 * 	 - SPIEN	- on
 * 	 - EESAVE	- off
 * 	 - BOOTSZ	- start = 0xf000
 * 	 - BOOTRST	- on
 * 	 - CKOPT	- on
 * 	 - BODLEVEL - VCC=2.7V
 * 	 - BODEN	- on
 * 	 - SUT_CKSEL- Ext.Crystal High frequ. Startup time 16CK + 4ms bootup
 *
 * Lockbits Settings
 *
 *   LOCKBITS: 0xEF
 *
 *   - no memory lock feature enabled
 *   - no lock on SPM and LPM in Application Section
 *   - SPM prohibited in Boot Section
 *
 */


/**********************************************************/
/* Serial Bootloader for Icescint GPB 				      */
/*                                                        */
/* 20170707: Modified for the Icescint GPB by Marek Penno */
/*           marek.penno@desy.de                          */
/* 20090308: integrated Mega changes into main bootloader */
/*           source by D. Mellis                          */
/* 20080930: hacked for Arduino Mega (with the 1280       */
/*           processor, backwards compatible)             */
/*           by D. Cuartielles                            */
/* 20070626: hacked for Arduino Diecimila (which auto-    */
/*           resets when a USB connection is made to it)  */
/*           by D. Mellis                                 */
/* 20060802: hacked for Arduino by D. Cuartielles         */
/*           based on a previous hack by D. Mellis        */
/*           and D. Cuartielles                           */
/*                                                        */
/* ------------------------------------------------------ */
/*                                                        */
/* based on stk500boot.c                                  */
/* Copyright (c) 2003, Jason P. Kyle                      */
/* All rights reserved.                                   */
/* see avr1.org for original file and information         */
/*                                                        */
/* This program is free software; you can redistribute it */
/* and/or modify it under the terms of the GNU General    */
/* Public License as published by the Free Software       */
/* Foundation; either version 2 of the License, or        */
/* (at your option) any later version.                    */
/*                                                        */
/* This program is distributed in the hope that it will   */
/* be useful, but WITHOUT ANY WARRANTY; without even the  */
/* implied warranty of MERCHANTABILITY or FITNESS FOR A   */
/* PARTICULAR PURPOSE.  See the GNU General Public        */
/* License for more details.                              */
/*                                                        */
/* You should have received a copy of the GNU General     */
/* Public License along with this program; if not, write  */
/* to the Free Software Foundation, Inc.,                 */
/* 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA */
/*                                                        */
/* Licence can be viewed at                               */
/* http://www.fsf.org/licenses/gpl.txt                    */
/*                                                        */
/**********************************************************/

/* some includes */
#include <inttypes.h>
#include <avr/io.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <util/delay.h>
#include <avr/eeprom.h>

/* Use the F_CPU defined in Makefile */

#define AUTOBOOT_TIMEOUT	5000 // ms to wait until autoboot kicks in

/* set the UART baud rate */
/* 20060803: hacked by DojoCorp */
//#define BAUD_RATE   115200
#ifndef BAUD_RATE
#define BAUD_RATE   9600
#define BAUD_RATE2	57600
#endif

// Pin to control direction of the RS485 half-duplex mode
#define PIN_RS485_DE  4

/* SW_MAJOR and MINOR needs to be updated from time to time to avoid warning message from AVR Studio */
/* never allow AVR Studio to do an update !!!! */
#define HW_VER	 0x01
#define SW_VER   0x01

/* onboard LED is used to indicate, that the bootloader was entered (3x flashing) */
/* if monitor functions are included, LED goes on after monitor was entered */
#define LED_DDR  DDRD
#define LED_PORT PORTD
#define LED_PIN  PIND
#define LED      PIND0

#define PAGE_SIZE	0x80U	//128 words

#if defined __AVR_ATmega128__
#else
	#error "boot loader optimized for atmega128 for the icescint gpb"
#endif

// #define DEBUG_UART 1

/* function prototypes */
void putch(unsigned char);
char getch(void);
void getNch(uint8_t);
void byte_response(uint8_t);
char gethex(void);
void puthex(char);

#ifdef DEBUG_UART
	void puthex2(char);
	void putch2(char ch);
	void flash_led(uint8_t);
#endif

void uart0_set_write(char _value);

void beginPacket(unsigned short _size, unsigned char _type);
void endPacket(void);

/* some variables */
union address_union {
	uint16_t word;
	uint8_t  byte[2];
} address;

union length_union {
	uint16_t word;
	uint8_t  byte[2];
} length;

struct flags_struct {
	unsigned eeprom : 1;
	unsigned rampz  : 1;
} flags;


typedef enum {
	MODE_PACKET_HEADER1,
	MODE_PACKET_HEADER2,
	MODE_PACKET_SIZE1,
	MODE_PACKET_SIZE2,
	MODE_PACKET_TYPE,
	MODE_PACKET_DATA,
	MODE_PACKET_IGNORE_DATA,
	MODE_PACKET_CHECKSUM,
	MODE_PACKET_TAIL1,
	MODE_PACKET_TAIL2,
} cmd_mode_t;

#define PACKET_HEADER1 0xCA
#define PACKET_HEADER2 0xFE
#define PACKET_TAIL1   0xEF
#define PACKET_TAIL2   0xAC

#define CMD_ISP_ID 			1
#define CMD_WRITE_FLASH 	2
#define CMD_READ_FLASH		3
#define CMD_INVALID_PACKET  4
#define CMD_START_APP		5

cmd_mode_t cmd_mode;
#define CMD_BINARY_MAX_SIZE 260
static unsigned short cmd_binary_size;
static unsigned short cmd_binary_wrpos;
static unsigned char cmd_binary_type;
uint8_t cmd_binary_data[CMD_BINARY_MAX_SIZE];
static unsigned char cmd_binary_data_valid;
static unsigned char cmd_sender_checksum;

uint8_t buff[256];
uint8_t address_high;
uint8_t pagesz=0x80;
uint8_t i;
uint8_t error_count = 0;
uint8_t autoBootEnabled=1;

void (*app_start)(void) = 0x0000;

/* main program starts here */
int main(void)
{
	uint8_t ch;
	uint16_t w;

#ifdef WATCHDOG_MODS
	ch = MCUSR;
	MCUSR = 0;

	WDTCSR |= _BV(WDCE) | _BV(WDE);
	WDTCSR = 0;

	// Check if the WDT was used to reset, in which case we dont bootload and skip straight to the code. woot.
	if (! (ch &  _BV(EXTRF))) // if its a not an external reset...
		app_start();  // skip bootloader
#else
	asm volatile("nop\n\t");
#endif

	/* initialize UART(s)  */


	DDRE|=PIN_RS485_DE; // activate output control pin
	PORTE&=~_BV(PIN_RS485_DE);

	UBRR0L = (uint8_t)(F_CPU/(BAUD_RATE*16L)-1);
	UBRR0H = (F_CPU/(BAUD_RATE*16L)-1) >> 8;
	UCSR0A = 0x00;
	UCSR0C = 0x06;
	// enable receiver, disable transmitter
	UCSR0B = _BV(RXEN0);
	UCSR0B&=~_BV(TXEN0);

#ifdef DEBUG_UART
		UBRR1L = (uint8_t)(F_CPU/(BAUD_RATE2*16L)-1);
		UBRR1H = (F_CPU/(BAUD_RATE*16L)-1) >> 8;
		UCSR1A = 0x00;
		UCSR1C = 0x06;
		UCSR1B = _BV(TXEN1)|_BV(RXEN1);
		/* set LED pin as output */
		LED_DDR |= _BV(LED);
		/* flash onboard LED to signal entering of bootloader */
		// 4x for UART0, 5x for UART1
		flash_led(NUM_LED_FLASHES + bootuart);
#endif

	unsigned char packetReady=0;
	unsigned char checksum=0;
	cmd_mode=MODE_PACKET_HEADER2;

#ifdef DEBUG_UART
	putch2('T');
	putch2('E');
	putch2('S');
	putch2('T');
#endif

	/* forever loop */
	for (;;) {

		packetReady=0;

		/* get character from UART */
		ch = getch();

		if (cmd_mode!=MODE_PACKET_CHECKSUM) checksum+=ch;

		// enter packet mode
		if (cmd_mode==MODE_PACKET_HEADER1) {
			if (ch==PACKET_HEADER1) {
				checksum=PACKET_HEADER1;
				cmd_mode=MODE_PACKET_HEADER2;
			}
		}
		else if (cmd_mode==MODE_PACKET_HEADER2) {
			if (ch==PACKET_HEADER1) {
				checksum=PACKET_HEADER1;
				cmd_mode=MODE_PACKET_HEADER2;
			} else if (ch==PACKET_HEADER2) {
				cmd_mode=MODE_PACKET_TYPE;
			} else {
				// Packet Error
				cmd_mode=MODE_PACKET_HEADER1;
			}
		}
		else if(cmd_mode==MODE_PACKET_TYPE) {
			cmd_binary_type = ch;
			cmd_mode=MODE_PACKET_SIZE1;
		}
		else if(cmd_mode==MODE_PACKET_SIZE1) {
			cmd_binary_size=ch;
			cmd_mode=MODE_PACKET_SIZE2;
//			putch2('2');
		}
		else if(cmd_mode==MODE_PACKET_SIZE2) {
			cmd_binary_size|=(ch << 8);
			cmd_binary_wrpos=0;
			cmd_binary_data_valid=0;
			if (cmd_binary_size==0) {
				cmd_mode=MODE_PACKET_CHECKSUM;
			} else if (cmd_binary_size<CMD_BINARY_MAX_SIZE) {
				cmd_mode=MODE_PACKET_DATA;
			} else {
				// Error, Packet to big
#ifdef DEBUG_UART
				putch2('3');
				putch2('E');
#endif
				cmd_mode=MODE_PACKET_IGNORE_DATA;
			}
		}
		else if(cmd_mode==MODE_PACKET_DATA) {
//			putch2('4');
			cmd_binary_data[cmd_binary_wrpos]=ch;
			cmd_binary_wrpos++;
			if (cmd_binary_wrpos==cmd_binary_size) {
				cmd_mode=MODE_PACKET_CHECKSUM;
				cmd_binary_data_valid=1;
			}
		}
		else if (cmd_mode==MODE_PACKET_IGNORE_DATA) {
//			putch2('5');
			cmd_binary_wrpos++;
			if (cmd_binary_wrpos==cmd_binary_size) {
				cmd_mode=MODE_PACKET_CHECKSUM;
			}
		}
		else if (cmd_mode==MODE_PACKET_CHECKSUM) {
			if (checksum==ch) {
				cmd_mode=MODE_PACKET_TAIL1;
			} else {
				// checksum error
#ifdef DEBUG_UART
				putch2('C');
				putch2('S');
				putch2('E');
				putch2(' ');
				puthex2(ch);
				putch2(' ');
				puthex2(checksum);
				putch2('.');
#endif
				cmd_mode=MODE_PACKET_HEADER1;
			}
		}
		else if (cmd_mode==MODE_PACKET_TAIL1) {
			if (ch==PACKET_TAIL1) {
				cmd_mode=MODE_PACKET_TAIL2;
			} else {
				cmd_mode=MODE_PACKET_HEADER1;
#ifdef DEBUG_UART
				putch2('6');
				putch2('E');
				putch2(' ');
				puthex2(ch);
#endif
			}
		}
		else if (cmd_mode==MODE_PACKET_TAIL2) {
#ifdef DEBUG_UART
			putch2('7');
#endif
			if (ch==PACKET_TAIL2) {
#ifdef DEBUG_UART
				putch2('7');
				putch2('!');
#endif
				packetReady=1;
				cmd_mode=MODE_PACKET_HEADER2;
			} else {
#ifdef DEBUG_UART
				putch2('7');
				putch2('E');
#endif
				cmd_mode=MODE_PACKET_HEADER1;
				// Packet Error
			}
		} else {
			cmd_mode=MODE_PACKET_HEADER1;
		}


		if (!packetReady) continue;

		autoBootEnabled=0; // disable autoboot mode, on any valid packet

#ifdef DEBUG_UART
		flash_led(1);
#endif

#ifdef DEBUG_UART
		puthex2(cmd_binary_size);
#endif
		// Received a packet!

		if (cmd_binary_type==CMD_ISP_ID)
		{
#ifdef DEBUG_UART
			putch2('I');
			putch2('D');
			putch2('?');
#endif
			// Answer with ISP ID

			beginPacket(19, CMD_ISP_ID);

			// send hardware and software version
			putch(HW_VER);
			putch(SW_VER);

			// send our id
			putch('I');
			putch('C');
			putch('E');
			putch('S');
			putch('C');
			putch('I');
			putch('N');
			putch('T');
			putch(' ');
			putch('G');
			putch('P');
			putch('B');
			putch(' ');
			putch('B');
			putch('O');
			putch('O');
			putch('T');

			endPacket();

			continue;
		}

		else if (cmd_binary_type==CMD_WRITE_FLASH)
		{
#ifdef DEBUG_UART
			putch2('W');
			putch2('R');
			putch2('!');
#endif
			address.byte[0] = cmd_binary_data[0];
			address.byte[1] = cmd_binary_data[1];
			//buff=&cmd_binary_data[2];
			length.word = cmd_binary_size - 2;
			int i;
			for (i=0;i<cmd_binary_size-2;i++) {
#ifdef DEBUG_UART
				puthex2(cmd_binary_data[i+2]);
				putch2(' ');
#endif
				buff[i]=cmd_binary_data[i+2];
			}

			if (address.byte[1]>127) address_high = 0x01;	//Only possible with m128, m256 will need 3rd address byte. FIXME
			else address_high = 0x00;

			RAMPZ = address_high;

			//address.word = address.word; << 1;	        //address * 2 -> byte location
			/* if ((length.byte[0] & 0x01) == 0x01) length.word++;	//Even up an odd number of bytes */
			if ((length.byte[0] & 0x01)) length.word++;	//Even up an odd number of bytes
			cli();					//Disable interrupts, just to be sure

			while(bit_is_set(EECR,EEWE));			//Wait for previous EEPROM writes to complete

			asm volatile(
				 "clr	r17		\n\t"	//page_word_count
				 "lds	r30,address	\n\t"	//Address of FLASH location (in bytes)
				 "lds	r31,address+1	\n\t"
				 "ldi	r28,lo8(buff)	\n\t"	//Start of buffer array in RAM
				 "ldi	r29,hi8(buff)	\n\t"
//				 "ldi	r28,%1	\n\t"	//Start of buffer array in RAM
//				 "ldi	r29,%1+1	\n\t"
				 "lds	r24,length	\n\t"	//Length of data to be written (in bytes)
				 "lds	r25,length+1	\n\t"
				 "length_loop:		\n\t"	//Main loop, repeat for number of words in block
				 "cpi	r17,0x00	\n\t"	//If page_word_count=0 then erase page
				 "brne	no_page_erase	\n\t"
				 "wait_spm1:		\n\t"
				 "lds	r16,%0		\n\t"	//Wait for previous spm to complete
				 "andi	r16,1           \n\t"
				 "cpi	r16,1           \n\t"
				 "breq	wait_spm1       \n\t"
				 "ldi	r16,0x03	\n\t"	//Erase page pointed to by Z
				 "sts	%0,r16		\n\t"
				 "spm			\n\t"

				 "wait_spm2:		\n\t"
				 "lds	r16,%0		\n\t"	//Wait for previous spm to complete
				 "andi	r16,1           \n\t"
				 "cpi	r16,1           \n\t"
				 "breq	wait_spm2       \n\t"

				 "ldi	r16,0x11	\n\t"	//Re-enable RWW section
				 "sts	%0,r16		\n\t"
				 "spm			\n\t"

				 "no_page_erase:		\n\t"
				 "ld	r0,Y+		\n\t"	//Write 2 bytes into page buffer
				 "ld	r1,Y+		\n\t"

				 "wait_spm3:		\n\t"
				 "lds	r16,%0		\n\t"	//Wait for previous spm to complete
				 "andi	r16,1           \n\t"
				 "cpi	r16,1           \n\t"
				 "breq	wait_spm3       \n\t"
				 "ldi	r16,0x01	\n\t"	//Load r0,r1 into FLASH page buffer
				 "sts	%0,r16		\n\t"
				 "spm			\n\t"

				 "inc	r17		\n\t"	//page_word_count++
				 "cpi r17,%1	        \n\t"
				 "brlo	same_page	\n\t"	//Still same page in FLASH
				 "write_page:		\n\t"
				 "clr	r17		\n\t"	//New page, write current one first
				 "wait_spm4:		\n\t"
				 "lds	r16,%0		\n\t"	//Wait for previous spm to complete
				 "andi	r16,1           \n\t"
				 "cpi	r16,1           \n\t"
				 "breq	wait_spm4       \n\t"

				 "ldi	r16,0x05	\n\t"	//Write page pointed to by Z
				 "sts	%0,r16		\n\t"
				 "spm			\n\t"

				 "wait_spm5:		\n\t"
				 "lds	r16,%0		\n\t"	//Wait for previous spm to complete
				 "andi	r16,1           \n\t"
				 "cpi	r16,1           \n\t"
				 "breq	wait_spm5       \n\t"
				 "ldi	r16,0x11	\n\t"	//Re-enable RWW section
				 "sts	%0,r16		\n\t"
				 "spm			\n\t"

				 "same_page:		\n\t"
				 "adiw	r30,2		\n\t"	//Next word in FLASH
				 "sbiw	r24,2		\n\t"	//length-2
				 "breq	final_write	\n\t"	//Finished
				 "rjmp	length_loop	\n\t"
				 "final_write:		\n\t"
				 "cpi	r17,0		\n\t"
				 "breq	block_done	\n\t"
				 "adiw	r24,2		\n\t"	//length+2, fool above check on length after short page write
				 "rjmp	write_page	\n\t"
				 "block_done:		\n\t"
				 "clr	__zero_reg__	\n\t"	//restore zero register
				 : "=m" (SPMCSR)
				 : "M" (PAGE_SIZE), "i" (&cmd_binary_data[2])
				 : "r0","r16","r17","r24","r25","r28","r29","r30","r31"
				 );
			/* Should really add a wait for RWW section to be enabled, don't actually need it since we never */
			/* exit the bootloader without a power cycle anyhow */


			// send answer, flashing finished
			beginPacket(0, CMD_WRITE_FLASH);

			endPacket();

			continue;
		}

		/* Read memory block mode, length is big endian.  */
		else if (cmd_binary_type==CMD_READ_FLASH) {
#ifdef DEBUG_UART
			putch2('R');
			putch2('D');
			putch2('?');
#endif

			address.byte[0] = cmd_binary_data[0];
			address.byte[1] = cmd_binary_data[1];

			length.byte[0] = cmd_binary_data[2];
			length.byte[1] = cmd_binary_data[3];

			if (address.word>0x7FFF) flags.rampz = 1;
			else flags.rampz = 0;

			// Acknowledge command, send back result
			beginPacket(length.word, CMD_READ_FLASH);

			for (w=0;w < length.word;w++) {		        // Can handle odd and even lengths okay
#ifdef DEBUG_UART
				putch2('r');
#endif
				if (!flags.rampz) putch(pgm_read_byte_near(address.word));
				else putch(pgm_read_byte_far(address.word + 0x10000));

				address.word++;
			}
			endPacket();

			continue;
		} else if(cmd_binary_type==CMD_START_APP) {
			// Acknowledge command
			beginPacket(0, CMD_START_APP);
			endPacket();

			// Start the application
			app_start();
		} else {

			beginPacket(0, CMD_INVALID_PACKET);
			endPacket();
		}

	} /* end of forever loop */
}

char gethexnib(void) {
	char a;
	a = getch(); putch(a);
	if(a >= 'a') {
		return (a - 'a' + 0x0a);
	} else if(a >= '0') {
		return(a - '0');
	}
	return a;
}


char gethex(void) {
	return (gethexnib() << 4) + gethexnib();
}


void puthex(char ch) {
	char ah;

	ah = ch >> 4;
	if(ah >= 0x0a) {
		ah = ah - 0x0a + 'a';
	} else {
		ah += '0';
	}
	
	ch &= 0x0f;
	if(ch >= 0x0a) {
		ch = ch - 0x0a + 'a';
	} else {
		ch += '0';
	}
	
	putch(ah);
	putch(ch);
}

#ifdef DEBUG_UART
void puthex2(char ch) {
	char ah;

	ah = ch >> 4;
	if(ah >= 0x0a) {
		ah = ah - 0x0a + 'a';
	} else {
		ah += '0';
	}

	ch &= 0x0f;
	if(ch >= 0x0a) {
		ch = ch - 0x0a + 'a';
	} else {
		ch += '0';
	}

	putch2(ah);
	putch2(ch);
}
#endif

void beginPacket(unsigned short _size, unsigned char _type)
{
	uart0_set_write(1);

	cmd_sender_checksum=0;
	putch(0xca);
	putch(0xfe);
	putch(_type);
	putch(_size & 0xff);
	putch((_size >> 8) & 0xff);
}

void endPacket(void)
{
	putch(cmd_sender_checksum); // TBD: CRC8 checksum for size, type and payload
	putch(0xef);
	putch(0xac);
	uart0_set_write(0);
}

void uart0_set_write(char _value)
{

	if (_value) {

		// transceiver is already enabled, just exit
		if (UCSR0B & _BV(TXEN0)) return;

		_delay_ms(10);
		//_delay_ms(10);

    	// disable receiver, enable transmitter
    	UCSR0B&=~_BV(RXEN0);
		UCSR0B|=_BV(TXEN0);

		PORTE|=_BV(PIN_RS485_DE);

#ifdef DEBUG_UART
		putch2('!');
#endif
	} else {

		// receiver is already enabled, just exit
		if (UCSR0B & _BV(RXEN0)) return;

		// wait for all data send
    	while (! (UCSR0A & _BV(TXC0)) ) {};

		_delay_ms(10);

		PORTE&=~_BV(PIN_RS485_DE);

	    // enable receiver, disable transmitter
		UCSR0B|=_BV(RXEN0);
		UCSR0B&=~_BV(TXEN0);

#ifdef DEBUG_UART
		putch2('?');
#endif
	}

}

void putch(unsigned char ch)
{
	cmd_sender_checksum+=ch;

	while (!(UCSR0A & _BV(UDRE0)));
	UCSR0A|=_BV(TXC0);
	UDR0 = ch;
}

#ifdef DEBUG_UART
void putch2(char ch)
{
	while (!(UCSR1A & _BV(UDRE1)));
	UDR1 = ch;
}
#endif

char getch(void)
{
	uint32_t count = 0;
	while(!(UCSR0A & _BV(RXC0))) {
		count++;
		if ((count > AUTOBOOT_TIMEOUT) && autoBootEnabled)
			app_start();
			;
		_delay_ms(1);
	}
	return UDR0;
}


void getNch(uint8_t count)
{
	while(count--) {
		uart0_set_write(0);
		while(!(UCSR0A & _BV(RXC0)));
		UDR0;
	}
}

#ifdef DEBUG_UART
void flash_led(uint8_t count)
{
	while (count--) {
		LED_PORT |= _BV(LED);
		_delay_ms(100);
		LED_PORT &= ~_BV(LED);
		_delay_ms(100);
	}
}
#endif

/* end of file ATmegaBOOT.c */
