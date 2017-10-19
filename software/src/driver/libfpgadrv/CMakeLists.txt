cmake_minimum_required(VERSION 2.6)

if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	FILE(GLOB_RECURSE SRCC *.c )
	FILE(GLOB_RECURSE SRCCPP *.cpp )
	SET(SRC ${SRCC} ${SRCCPP})

	include_directories( . )

#	include_directories( ${CMAKE_SOURCE_DIR}/taxi/fpgadrv )

	compile_library(fpgadrv "${SRC}" "") 

	install_library(fpgadrv)
		
else()
	# for x86 architecture, fpga firmware loader implementation is not needed
endif()

