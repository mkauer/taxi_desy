cmake_minimum_required(VERSION 2.6)

use_library( thrift LIBS)

FILE(GLOB_RECURSE SRCC *.c )
FILE(GLOB_RECURSE SRCCPP *.cpp )
SET(SRC ${SRCC} ${SRCCPP})

include_directories( . )

set(HESS1U_THRIFT_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/thriftSlowControl)
set(THRIFT_SRC )
thrift_generate(THRIFT_SRC ${HESS1U_THRIFT_SOURCE_DIR}/slowcontrol.thrift)

# remove all "*_skeleton.cpp" generated files (because of main symbol)
set(_SRC)
foreach(FILE ${SRC})
   GET_FILENAME_COMPONENT(NAME ${FILE} NAME_WE)

	IF("${NAME}" MATCHES "^[a-zA-Z\\-_]+(_server.skeleton.cpp)$")
		message("Remove file from compilation: ${NAME}")
	else()
		set(_SRC ${_SRC} ${FILE})
		#message("Keep file in compilation: ${NAME}")
	endif()
endforeach()

set(SRC ${SRC} ${THRIFT_SRC})

compile_library(icescint_common "${SRC}" "${LIBS}") 

#target_link_libraries(icescint_common ${LIBS})

install_library(icescint_common)
