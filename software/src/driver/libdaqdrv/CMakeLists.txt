cmake_minimum_required(VERSION 2.6)

if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	FILE(GLOB_RECURSE SRCC *.c )
	FILE(GLOB_RECURSE SRCCPP *.cpp )
	SET(SRC ${SRCC} ${SRCCPP})

	include_directories( . )

#	include_directories( ${CMAKE_SOURCE_DIR}/taxi/driver/smcdrv )

	compile_library(daqdrv "${SRC}" "") 

	install_library(daqdrv)
		
else()
	# for x86 architecture, direct bus access implementation is not needed
endif()

