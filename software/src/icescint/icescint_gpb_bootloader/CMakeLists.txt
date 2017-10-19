#use_arduino_lib()

include(${CMAKE_SOURCE_DIR}/cmake/avr-cross.cmake)

if (AVR_CC) 
    set(AVR_PROGRAMMER avrispmkII)
    set(AVR_UPLOAD_MCU m128)
	set(AVR_MCU atmega128)
	set(AVR_LDSECTION -Wl,--section-start=.text=0x1E000)
	
	add_definitions( -DNUM_LED_FLASHES=0 )
		
	add_avr_executable(icescint_bootloader "ATmegaBOOT.c" "${LIBS}")
else()
	message("WARNING! icescint_gpb cannot be compiled, missing avr compiler") 
endif()


       