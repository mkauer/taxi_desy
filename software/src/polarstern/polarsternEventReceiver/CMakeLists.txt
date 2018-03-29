cmake_minimum_required(VERSION 2.6)

include_directories( . )

set(SRC main.cpp)

use_library( boost LIBS )
use_library( zmq LIBS )

compile_executable(polarstern_eventReceiver "${SRC}" "${LIBS}")
 
install(TARGETS polarstern_eventReceiver RUNTIME DESTINATION ${INSTALL_BIN})