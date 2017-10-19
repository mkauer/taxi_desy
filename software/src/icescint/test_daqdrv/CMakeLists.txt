cmake_minimum_required(VERSION 2.6)

include_directories( . )

use_library( boost LIBS )
use_library( smcdrv LIBS )
use_library( taxihal LIBS )

compile_executable(test_directreadout "directReadout.cpp" "${LIBS}")
install(TARGETS test_directreadout RUNTIME DESTINATION ${INSTALL_BIN})

use_library( daqdrv LIBS )
use_library( common LIBS )

compile_executable(test_daqdrv "drvReadout.cpp" "${LIBS}")
install(TARGETS test_daqdrv RUNTIME DESTINATION ${INSTALL_BIN}) 
