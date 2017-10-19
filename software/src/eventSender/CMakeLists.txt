cmake_minimum_required(VERSION 2.6)

include_directories( . )

set(SRC main.cpp)

use_library( boost LIBS )
use_library( daqdrv LIBS )
use_library( common LIBS )
use_library( zmq LIBS )

compile_executable(eventSender "${SRC}" "${LIBS}")
 
install(TARGETS eventSender RUNTIME DESTINATION ${INSTALL_BIN})