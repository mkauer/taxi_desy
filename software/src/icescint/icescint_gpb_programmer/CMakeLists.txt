cmake_minimum_required(VERSION 2.6)

include_directories( . )

set(SRC main.cpp)

use_library( boost LIBS )
use_library( smcdrv LIBS)
use_library( icescint_gpb LIBS )
use_library( taxihal LIBS )

compile_executable(icescint_gpb_programmer "${SRC}" "${LIBS}")
install(TARGETS icescint_gpb_programmer RUNTIME DESTINATION ${INSTALL_BIN})

compile_executable(testTaxiSerial "testTaxiSerial.cpp" "${LIBS}")
install(TARGETS testTaxiSerial RUNTIME DESTINATION ${INSTALL_BIN})

