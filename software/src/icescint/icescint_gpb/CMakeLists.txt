#use_arduino_lib()

include(${CMAKE_SOURCE_DIR}/cmake/avr-cross.cmake)

if (AVR_CC) 
	set(AVR_MCU atmega128)
	
	include_directories(./libs)
	
	# add arduino libs
	set(ARDUINO_LIB_DIR ./libs/arduino)
	include_directories(${ARDUINO_LIB_DIR})
	
	set(ARDUINO_SRC 
		${ARDUINO_LIB_DIR}/wiring.c 
		${ARDUINO_LIB_DIR}/wiring_analog.c 
		${ARDUINO_LIB_DIR}/wiring_digital.c 
		${ARDUINO_LIB_DIR}/wiring_pulse.c
		${ARDUINO_LIB_DIR}/wiring_shift.c 
		${ARDUINO_LIB_DIR}/WInterrupts.c
		${ARDUINO_LIB_DIR}/new.cpp 
		${ARDUINO_LIB_DIR}/hooks.c
		${ARDUINO_LIB_DIR}/Print.cpp
		${ARDUINO_LIB_DIR}/HardwareSerial.cpp 
	#	${ARDUINO_LIB_DIR}/HardwareSerial0.cpp
		${ARDUINO_LIB_DIR}/HardwareSerial1.cpp
	#	${ARDUINO_LIB_DIR}/WMath.cpp
	)
	
	# add half duplex library
	include_directories( libs/HalfDuplexHardwareSerial) 
	
	set(SRC ${ARDUINO_SRC})
	set(SRC	${SRC} libs/HalfDuplexHardwareSerial/HalfDuplexHardwareSerial0.cpp) 
	set(SRC	${SRC} libs/HalfDuplexHardwareSerial/HalfDuplexHardwareSerial.cpp) 
	
	# main program
	include_directories(.)
	
	set(SRC	${SRC} Cmd.cpp main.cpp )
	
	add_avr_executable(icescint "${SRC}" "${LIBS}")
else()
	message("WARNING! icescint_gpb cannot be compiled, missing avr compiler") 
endif()


       