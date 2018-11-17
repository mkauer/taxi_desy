cmake_minimum_required(VERSION 2.6)

set(TOOLNAME uvlogger_rates)

include_directories( . )
set(SRC main.cpp)

use_library( taxihal LIBS )
use_library( smcdrv LIBS )
use_library( boost LIBS )

compile_executable(${TOOLNAME} "${SRC}" "${LIBS}")
 
install(TARGETS ${TOOLNAME} RUNTIME DESTINATION ${INSTALL_BIN})