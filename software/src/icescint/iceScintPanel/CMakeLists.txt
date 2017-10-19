cmake_minimum_required(VERSION 2.6)

include_directories( . )

set(SRC main.cpp)

use_library( taxihal LIBS )
use_library( smcdrv LIBS )
use_library( boost LIBS )

compile_executable(icescint_panel "${SRC}" "${LIBS}")
 
install(TARGETS icescint_panel RUNTIME DESTINATION ${INSTALL_BIN})