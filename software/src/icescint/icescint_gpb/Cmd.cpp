/*******************************************************************
    Copyright (C) 2009 FreakLabs
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:

    1. Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
    3. Neither the name of the the copyright holder nor the names of its contributors
       may be used to endorse or promote products derived from this software
       without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
    ARE DISCLAIMED.  IN NO EVENT SHALL THE INSTITUTE OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
    OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
    HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
    OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
    SUCH DAMAGE.

    Originally written by Christopher Wang aka Akiba.
    Please post support questions to the FreakLabs forum.

*******************************************************************/
/*!
    \file Cmd.c

    This implements a simple command line interface for the Arduino so that
    its possible to execute individual functions within the sketch. 
*/
/**************************************************************************/
#include <avr/pgmspace.h>
#if ARDUINO >= 100
#include <Arduino.h>
#else
#include <WProgram.h>
#endif
#include "HalfDuplexHardwareSerial.h"
#include "Cmd.h"

#include "protocol.h"

//HalfDuplexHardwareSerial HalfDuplexSerial(&UBRR0H, &UBRR0L, &UCSR0A, &UCSR0B, &UCSR0C, &UDR0);

// command line message buffer and pointer
static uint8_t msg[MAX_MSG_SIZE];
static uint8_t *msg_ptr;

// linked list for command table
static cmd_t *cmd_tbl_list, *cmd_tbl;

// text strings for command prompt (stored in flash)
const char cmd_banner[] PROGMEM = "*** IceScint RS485 command interface ***";
const char cmd_prompt[] PROGMEM = "CMD> ";
const char cmd_unrecog[] PROGMEM = "CMD: Command not recognized.";

#define PIN_RS485_DE _BV(4) // PORT E, PE4

typedef enum {
	MODE_CLI,
	MODE_PACKET
} cmd_mode_t;

static cmd_mode_t cmd_mode;
#define CMD_BINARY_MAX_SIZE 120
static unsigned char cmd_binary_size;
static unsigned char cmd_binary_wrpos;
static unsigned char cmd_binary_data[CMD_BINARY_MAX_SIZE];
static bool cmd_binary_data_valid;

packetDecoder_t packetDecoder;
packet_t		packet;

void cmd_setDirection(cmd_direction_t _mode)
{
	if (_mode==CMD_WRITE) {
		HalfDuplexSerial.beginWrite();
	} else if (_mode==CMD_READ) {
		HalfDuplexSerial.endWrite();
	}
}

/**************************************************************************/
/*!
    Generate the main command prompt
*/
/**************************************************************************/
void cmd_display()
{
    char buf[100];

    HalfDuplexSerial.println();

    strcpy_P(buf, cmd_banner);
    HalfDuplexSerial.println(buf);

    strcpy_P(buf, cmd_prompt);
    HalfDuplexSerial.print(buf);
}

/**************************************************************************/
/*!
    Parse the command line. This function tokenizes the command input, then
    searches for the command table entry associated with the commmand. Once found,
    it will jump to the corresponding function.
*/
/**************************************************************************/
void cmd_parse(char *cmd)
{
    uint8_t argc, i = 0;
    char *argv[30];
    char buf[100];
    cmd_t *cmd_entry;

    // parse the command line statement and break it up into space-delimited
    // strings. the array of strings will be saved in the argv array.
    argv[i] = strtok(cmd, " ");
    do
    {
        argv[++i] = strtok(NULL, " ");
    } while ((i < 30) && (argv[i] != NULL));
    
    // save off the number of arguments for the particular command.
    argc = i;

    // parse the command table for valid command. used argv[0] which is the
    // actual command name typed in at the prompt
    for (cmd_entry = cmd_tbl; cmd_entry != NULL; cmd_entry = cmd_entry->next)
    {
        if (!strcmp(argv[0], cmd_entry->cmd))
        {
            {
            	cmd_write_scope scope;
				cmd_entry->func(argc, argv);
				cmd_display();
            }
            return;
        }
    }

    // command not recognized. print message and re-generate prompt.
    {
		cmd_write_scope scope;
		strcpy_P(buf, cmd_unrecog);
		HalfDuplexSerial.println(buf);

		cmd_display();
    }
}

/**************************************************************************/
/*!
    This function processes the individual characters typed into the command
    prompt. It saves them off into the message buffer unless its a "backspace"
    or "enter" key. 
*/
/**************************************************************************/
void cmd_handler()
{
	//cmd_setDirection(CMD_READ);

    char c = HalfDuplexSerial.read();

    if (cmd_mode==MODE_CLI) {
		switch (c)
		{
		case PACKET_HEADER1:
			cmd_mode=MODE_PACKET;
			packetDecoder_processData(&packetDecoder, c);
			// First byte of the binary packet header
			break;
		case '\r':
			// terminate the msg and reset the msg ptr. then send
			// it to the handler for processing.
			*msg_ptr = '\0';

			{
				cmd_write_scope scope;
				HalfDuplexSerial.print("\r\n");
				cmd_parse((char *)msg);
			}
			msg_ptr = msg;
			break;

		case '\b':
			// backspace
			{
				cmd_write_scope scope;
				HalfDuplexSerial.print(c);
			}
			if (msg_ptr > msg)
			{
				msg_ptr--;
			}
			break;

		default:
			// normal character entered. add it to the buffer
			{
				cmd_write_scope scope;
				HalfDuplexSerial.print(c);
			}
			*msg_ptr++ = c;
			break;
		}
    } else {
    	// in packet processing mode
    	// decode packet...
    	if (packetDecoder_processData(&packetDecoder, c))
    	{
    		// packet detected, call callback
    		packetHandler(&packet);
    		// switch back to cli mode
    		cmd_mode=MODE_CLI;
    	} else if (packetDecoder.mode==MODE_PACKET_HEADER1) {
    		cmd_mode=MODE_CLI;
    	}

    }
}

/**************************************************************************/
/*!
    This function should be set inside the main loop. It needs to be called
    constantly to check if there is any available input at the command prompt.
*/
/**************************************************************************/
void cmdPoll()
{
    while (HalfDuplexSerial.available())
    {
        cmd_handler();
    }
}

/**************************************************************************/
/*!
    Initialize the command line interface. This sets the terminal speed and
    and initializes things. 
*/
/**************************************************************************/
void cmdInit(uint32_t speed)
{
    // init the msg ptr
    msg_ptr = msg;

    // init the command table
    cmd_tbl_list = NULL;

    cmd_mode=MODE_CLI;

    // initialize packet storage
    packet_init(&packet, 0, cmd_binary_data, CMD_BINARY_MAX_SIZE);
    // initialize decoder
    packetDecoder_init(&packetDecoder, &packet);

    // set the HalfDuplexSerial speed
    HalfDuplexSerial.begin(speed);
}

/**************************************************************************/
/*!
    Add a command to the command table. The commands should be added in
    at the setup() portion of the sketch. 
*/
/**************************************************************************/
void cmdAdd(const char *name, void (*func)(int argc, char **argv))
{
    // alloc memory for command struct
    cmd_tbl = (cmd_t *)malloc(sizeof(cmd_t));

    // alloc memory for command name
    char *cmd_name = (char *)malloc(strlen(name)+1);

    // copy command name
    strcpy(cmd_name, name);

    // terminate the command name
    cmd_name[strlen(name)] = '\0';

    // fill out structure
    cmd_tbl->cmd = cmd_name;
    cmd_tbl->func = func;
    cmd_tbl->next = cmd_tbl_list;
    cmd_tbl_list = cmd_tbl;
}

/**************************************************************************/
/*!
    Convert a string to a number. The base must be specified, ie: "32" is a
    different value in base 10 (decimal) and base 16 (hexadecimal).
*/
/**************************************************************************/
uint32_t cmdStr2Num(char *str, uint8_t base)
{
    return strtol(str, NULL, base);
}
