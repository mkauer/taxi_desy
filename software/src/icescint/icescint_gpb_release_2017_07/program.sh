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
