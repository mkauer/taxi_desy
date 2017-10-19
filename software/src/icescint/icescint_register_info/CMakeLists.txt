cmake_minimum_required(VERSION 2.6)

FILE(GLOB SRC *.cpp *.cc *.c)

include_directories( . )

use_library( boost LIBS)
use_library( smcdrv LIBS)
use_library( daqdrv LIBS)
use_library( common LIBS)
use_library( taxihal LIBS)

compile_executable(icescint_register_info "${SRC}" "${LIBS}")

install(TARGETS icescint_register_info RUNTIME DESTINATION ${INSTALL_BIN})