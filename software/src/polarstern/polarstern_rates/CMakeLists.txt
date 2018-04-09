cmake_minimum_required(VERSION 2.6)

include_directories( . )

set(SRC main.cpp)

use_library( taxihal LIBS )
use_library( smcdrv LIBS )
use_library( boost LIBS )
use_library( common LIBS)

compile_executable(polarstern_rates "${SRC}" "${LIBS}")
 
install(TARGETS polarstern_rates RUNTIME DESTINATION ${INSTALL_BIN})