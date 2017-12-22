cmake_minimum_required(VERSION 2.6)

include_directories( . )

set(SRC main.cpp)

use_library( boost LIBS )
use_library( smcdrv LIBS)
use_library( icescint_gpb LIBS )
use_library( taxihal LIBS )

compile_executable(icescint_gpb_client "${SRC}" "${LIBS}")

install(TARGETS icescint_gpb_client RUNTIME DESTINATION ${INSTALL_BIN})