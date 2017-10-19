Icescint General Purpose Board Documentation
============================================

RS485 Interface Parameter
-------------------------
  - 9600 baud
  - no Paritiy
  - 1 Stopbit
  - half duplex !
  
This applies to the bootloaded and the actual 
main application running on the atmel cpu.
  
Bootloader
----------
On power on, a boot loader is automatically started within 5ms. 
The boot loader waits for command packets to read or write the 
flash memory or to start the application code from flash memory.

If within 5 seconds after powerup no valid boot loader command packet 
has been received, the bootloader automatically starts the application.

Command Interface
-----------------

- Press enter, and a command line prompt should be printed.
- enter "help" and press <enter> to view small help information
- use "pmt <command>" to send commands to the Hamamatsu Power Supply
  commands are directly send to the Hamamatsu power supply automatically 
  framed (see datasheet: <STX><DATA...><ETX><Checksum><LF>)
  

Flashing the Bootloader and Application
---------------------------------------
This applies to virgin board, when a bootloader, fuses and lock bits must be
configured first. Using the avrispmkII programmer connected via USB.

	avrdude -B 8 -P usb -c avrispmkII -p m128 -e
	
	avrdude -B 8 -P usb -c avrispmkII -p m128 \
	 -U efuse:w:0xFF:m      \
	 -U hfuse:w:0x88:m      \
	 -U lfuse:w:0xAF:m	
	
	avrdude -B 3 -P usb -c avrispmkII -p m128 \
	 -D \
	 -U flash:w:icescint_bootloader-atmega128.hex \
	 -U flash:w:icescint-atmega128.hex 
	
	avrdude -B 3 -P usb -c avrispmkII -p m128 \
	 -D -U loc:w:0xEF:m   
