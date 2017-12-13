#include <Arduino.h>
#include <HalfDuplexHardwareSerial.h>
#include <Cmd.h>

/*
 * version 1.0
 * version 1.1 - added packet decoder and sender
 */

// fuses must be set in mcu, in order to function correctly:
// - BODEN   = 1
// - BODLEV  = 2.7V
// - M103C   = 0
// - CKOPT   = 0 (perspective of AVR Studio
// - Ext Crystal Med Freq Startup time 16k ck + 0ms

// FUSES must be: 0x9F 0x89 0xFF

// RS485 Connection:
// When connecting from a computer with a USB-FTDI-RS485 dongle, you need to disable flow control!
//

//#define PIN_RS485_DE 4 // PE4
#define PIN_RXLB_SEL 5 // PE5
#define PIN_TERM_ENA 3 // PE3
#define PIN_LG_SEL   7 /* does not exist as arduino pin */     // PE7

//#define PIN_TEST_LED_SCL 21 // PD0

//bool led_blink_enb = false;
//int led_blink_delay_time = 1000;

// converts a ascii byte representated hex nibble (0..9 , a..f or A..F) into a integer 0..15
// on success returns integere 0..15
// on error returns -1
static inline char gethexnib(char a) {
	a=tolower(a);
	if(a >= 'a' && a<='f') {
		return (a - 'a' + 0x0a);
	} else if(a >= 'A' && a<='F') {
		return (a - 'F' + 0x0a);
	} else if(a >= '0' && a <='9') {
		return(a - '0');
	}
	return -1;
}

unsigned int getU16From4Hex(char* buf, int len=4)
{
	unsigned int r=0;
	for (int i=0;i<len;i++) {
		r=r << 4;
		r|=gethexnib(buf[i]);
	}
	return r;
}

char nibbleToHex(char val) {
	val&=0xf;
	if((val) >= 0x0a) {
		return 'A' + (val-10);
	} else {
		return '0' + (val);
	}
}

// packet type definitions 0x0 - 0xf reserved for boot loader
#define PACKET_TYPE_TEST 	0x10
#define PACKET_TYPE_LGSEL 	0x11
#define PACKET_TYPE_RXLBSEL 0x12
#define PACKET_TYPE_PMT		0x13
#define PACKET_TYPE_STATUS	0x14
#define PACKET_TYPE_UNKNOWN	0x15

typedef enum {
	PMT_ANSWER_CLI,
	PMT_ANSWER_PACKET,
} pmt_answer_mode_t;

pmt_answer_mode_t pmt_answer_mode=PMT_ANSWER_CLI;

// Photo Multiplier Hamamatsu Power Supply Protocol (CL204-02)

typedef enum {
	PMT_DECODER_MODE_STX,
	PMT_DECODER_MODE_DATA,
	PMT_DECODER_MODE_IGNORE_DATA,
	PMT_DECODER_MODE_CHECKSUM1,
	PMT_DECODER_MODE_CHECKSUM2,
	PMT_DECODER_MODE_DELIM,
} pmt_decoder_mode_t;

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

// serializes packet into a buffer with packet frame
int packet_send(uint8_t _type, unsigned char* _buf, size_t _size)
{
	unsigned char checksum=0;
#define SEND(X) do { HalfDuplexSerial.write(X); checksum+=X; } while(0)

	HalfDuplexSerial.beginWrite();
	SEND(0xca);
	SEND(0xfe);
	SEND(_type);
	SEND(_size & 0xff);
	SEND((_size >> 8) & 0xff);

	for (int i=0;i<_size;i++) SEND(_buf[i]);

	HalfDuplexSerial.write(checksum);
	HalfDuplexSerial.write(0xef);
	HalfDuplexSerial.write(0xac);
	HalfDuplexSerial.endWrite();
	return _size+8;
#undef SEND
}

// set lgsel pin to 1 or 0
void set_lgsel(int val)
{
	if (val) {
		PORTE|=_BV(PIN_LG_SEL);
	} else {
		PORTE&=~_BV(PIN_LG_SEL);
	}
}
// returns current lg pin setting 0 (clear) or 1 (set)
int get_lgsel(void)
{
	return (PORTE & _BV(PIN_LG_SEL))?1:0;
}
// set rxlbsel pin to 1 or to 0
void set_rxlbsel(int val)
{
	if (val) {
		PORTE|=_BV(PIN_RXLB_SEL);
	} else {
		PORTE&=~_BV(PIN_RXLB_SEL);
	}
}
// returns current rxlbsel pin 0 (clear) or 1 (set)
int get_rxlbsel(void)
{
	return (PORTE & _BV(PIN_RXLB_SEL))?1:0;
}

void packetHandler(packet_t* _packet)
{
	unsigned char buf[50];

	if (_packet->type==PACKET_TYPE_TEST)
	{
		// received test packet, just answer with similar packet
		buf[0]=4;
		buf[1]=3;
		buf[2]=2;
		buf[3]=1;
		packet_send(PACKET_TYPE_TEST, buf, 4);
		return;
	}
	if (_packet->type==PACKET_TYPE_LGSEL)
	{
		set_lgsel(_packet->data[0]);
		packet_send(PACKET_TYPE_LGSEL, buf, 0);
		return;
	}
	if (_packet->type==PACKET_TYPE_RXLBSEL)
	{
		set_rxlbsel(_packet->data[0]);
		packet_send(PACKET_TYPE_RXLBSEL, buf, 0);
		return;
	}
	if (_packet->type==PACKET_TYPE_PMT)
	{
		// forward command to pmt
		unsigned char checksum=0;
#define SEND(X) do  { Serial1.write(X); checksum+=X; } while(0)
		SEND(0x02); // STX
		for (int i=0;i<_packet->size;i++) SEND(_packet->data[i]);
		SEND(0x03);
		Serial1.write(nibbleToHex(checksum >> 4));
		Serial1.write(nibbleToHex(checksum & 0xf));
		Serial1.write(0x0d);
#undef SEND
		pmt_answer_mode=PMT_ANSWER_PACKET;
		return;
	}
	if (_packet->type==PACKET_TYPE_STATUS)
	{
		// received test packet, just answer with similar packet
		buf[0]=get_lgsel();
		buf[1]=get_rxlbsel();
		packet_send(PACKET_TYPE_STATUS, buf, 2);
		return;
	}

	buf[0]=_packet->type;
	buf[1]=_packet->size & 0xff;
	buf[2]=_packet->size >> 8;

	packet_send(PACKET_TYPE_UNKNOWN, buf, 3);


}

// **** CLI Command Implementation

// Usage:
// hello
void help(int arg_cnt, char **args)
{
	HalfDuplexSerial.write("help    - print this help\r\n");
	HalfDuplexSerial.write("hello   - hello world test\r\n");
	HalfDuplexSerial.write("pmt     - send command to Hamamats pmt power controller via rs232\r\n");
	HalfDuplexSerial.write("lgsel   - (0) hg-in => hg-out , (1) lg => hg-out \r\n");
	HalfDuplexSerial.write("rxlbsel	- (0) 1k-gnd => lg-in , (1) rs485-rx => lg-in \r\n");
	HalfDuplexSerial.write("status	- print status\r\n");
	HalfDuplexSerial.write("pmt HPO - get monitor info and status\r\n");
}

// Print "hello world" when called from the command line.
//
// Usage:
// hello
void hello(int arg_cnt, char **args)
{
	HalfDuplexSerial.println("Hello world!\r\n");
}

// pmt command
void send(int arg_cnt, char **args)
{
	if (arg_cnt<0) {
		HalfDuplexSerial.println("send: need 1 parameter, ex.g.: send HPO\r\n");
		return;
	}
	char buf[100];
	int len=strlen(args[1]);
	if (len>=52) {
		HalfDuplexSerial.println("send: string must be < 52 bytes\r\n");
		return;
	}
	unsigned char checksum=0x02;
	buf[0]=0x02; // STX
	for (int i=0;i<len;i++) {
		buf[1+i]=args[1][i];
		checksum+=args[1][i];
	}
	buf[len+1]=0x03; // STX
	checksum+=0x03;
	buf[len+2]=nibbleToHex((checksum >> 4));
	buf[len+3]=nibbleToHex((checksum & 0xf));
	buf[len+4]=0x0d;

	HalfDuplexSerial.println("Sending command via rs232.\r\n");
	Serial1.write(buf,len+5);

	pmt_answer_mode=PMT_ANSWER_CLI;
}

// lgsel command
void lgsel(int arg_cnt, char **args)
{
	if (arg_cnt>0) {
		if (!strcmp("1",args[1])) {
			HalfDuplexSerial.write("lgsel='1'\r\n");
			PORTE|=_BV(PIN_LG_SEL);
		} else if (!strcmp("0",args[1])) {
			HalfDuplexSerial.write("lgsel='0'\r\n");
			PORTE&=~_BV(PIN_LG_SEL);
		} else {
			HalfDuplexSerial.write("lgsel invalid parameter: '");
			HalfDuplexSerial.write(args[1]);
			HalfDuplexSerial.write("'\r\n");
		}
	} else {
		HalfDuplexSerial.write("lgsel = ");
		if (PORTE & _BV(PIN_LG_SEL)) {
			HalfDuplexSerial.write("1\r\n");
		} else {
			HalfDuplexSerial.write("0\r\n");
		}
	}
}

// rxlbsel command
void rxlbsel(int arg_cnt, char **args)
{
	if (arg_cnt>0) {
		if (!strcmp("1",args[1])) {
			HalfDuplexSerial.write("rxlbsel='1'\r\n");
			PORTE|=_BV(PIN_RXLB_SEL);
		} else if (!strcmp("0",args[1])) {
			HalfDuplexSerial.write("rxlbsel='0'\r\n");
			PORTE&=~_BV(PIN_RXLB_SEL);
		} else {
			HalfDuplexSerial.write("rxlbsel invalid parameter: '");
			HalfDuplexSerial.write(args[1]);
			HalfDuplexSerial.write("'\r\n");
		}
	} else {
		HalfDuplexSerial.write("rxlb = ");
		if (PORTE & _BV(PIN_RXLB_SEL)) {
			HalfDuplexSerial.write("1\r\n");
		} else {
			HalfDuplexSerial.write("0\r\n");
		}
	}
}

// status command
void status(int arg_cnt, char **args)
{
	HalfDuplexSerial.write("lgsel = ");
	if (PORTE & _BV(PIN_LG_SEL)) {
		HalfDuplexSerial.write("1\r\n");
	} else {
		HalfDuplexSerial.write("0\r\n");
	}
	HalfDuplexSerial.write("rxlb = ");
	if (PORTE & _BV(PIN_RXLB_SEL)) {
		HalfDuplexSerial.write("1\r\n");
	} else {
		HalfDuplexSerial.write("0\r\n");
	}
}

/*
void test(int arg_cnt, char **args)
{
	HalfDuplexSerial.println("running test.\r\n");
}

void baud(int arg_cnt, char **args)
{
	HalfDuplexSerial.println("set baud rate to\r\n");
}

void save(int arg_cnt, char **args)
{
	HalfDuplexSerial.println("settings stored\r\n");
}
*/

int counter=0;

pmt_decoder_t pmt_decoder;

void setup() {
  // initialize both serial ports:
//  Serial.begin(9600);
  Serial1.begin(38400, SERIAL_8E1);

  // init the command line and set it for a speed of 9600
  cmdInit(9600);

  // add the commands to the command table. These functions must
  // already exist in the sketch. See the functions below.
  // The functions need to have the format:
  //
  // void func_name(int arg_cnt, char **args)
  //
  // arg_cnt is the number of arguments typed into the command line
  // args is a list of argument strings that were typed into the command line
  cmdAdd("hello", hello);
  cmdAdd("pmt", send);
  cmdAdd("help", help);
  cmdAdd("lgsel", lgsel);
  cmdAdd("rxlbsel", rxlbsel);
  cmdAdd("status", status);

  DDRE=DDRE | 0b10111000; // activate all output control pins
  DDRD=1;

  //cmd_write_scope scope;
/*  HalfDuplexSerial.beginWrite();
  HalfDuplexSerial.println("*** Icescint GDB Application v1.1 - booting ***\r\n");
  HalfDuplexSerial.endWrite();
  */

  pmt_decoder_init(&pmt_decoder);

  counter=0;
}

long toggle=0;

unsigned char s[100];
int s_pos=0;

void loop()
{

  cmdPoll();

  // read from port 0, send to port 1:
  if (Serial1.available()) {
	  int inByte = Serial1.read();

	  int res=pmt_decoder_process(&pmt_decoder, inByte);
	  if (res) {
		  if (pmt_answer_mode==PMT_ANSWER_CLI) {
			  HalfDuplexSerial.beginWrite();
			  HalfDuplexSerial.write("\r\n");

			  HalfDuplexSerial.write("pmt: '");
			  HalfDuplexSerial.write(pmt_decoder.data, pmt_decoder.data_len);
			  HalfDuplexSerial.write("' ");
			  if (pmt_decoder.checksum!=pmt_decoder.checksum_received) {
				  HalfDuplexSerial.write("checksum mismatch!");

				  HalfDuplexSerial.write(nibbleToHex(pmt_decoder.checksum>>4));
				  HalfDuplexSerial.write(nibbleToHex(pmt_decoder.checksum));

				  HalfDuplexSerial.write("!=");
				  HalfDuplexSerial.write(nibbleToHex(pmt_decoder.checksum_received>>4));
				  HalfDuplexSerial.write(nibbleToHex(pmt_decoder.checksum_received));

			  }
			  HalfDuplexSerial.write("\r\nCMD>");
			  HalfDuplexSerial.endWrite();
		  } else {
			  // send back pmt answer as packet
			  packet_send(PACKET_TYPE_PMT, (unsigned char*)pmt_decoder.data, pmt_decoder.data_len);
		  }
	  }
  }
}

void main(void) __attribute__ ((noreturn));
void main(void)
{

	init();

	setup();

	sei();

	for (;;) {
		loop();
		//if (serialEventRun) serialEventRun();
	}
}

