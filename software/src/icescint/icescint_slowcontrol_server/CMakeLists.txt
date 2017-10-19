cmake_minimum_required(VERSION 2.6)

use_library( taxihal LIBS )
use_library( smcdrv LIBS )
use_library( boost LIBS)
use_library( thrift LIBS)
use_library( icescint_common LIBS)

set(SRC main.cpp)

compile_executable(icescint_slowcontrol_server "${SRC}" "${LIBS}")

install(TARGETS icescint_slowcontrol_server RUNTIME DESTINATION ${INSTALL_BIN})
