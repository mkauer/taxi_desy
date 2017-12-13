cmake_minimum_required(VERSION 2.6)

include_directories( . )

use_library( taxihal LIBS )
use_library( smcdrv LIBS )
use_library( daqdrv LIBS )
use_library( boost LIBS )

# original version of marko
compile_executable(icescint_drs4BaselineCalibrator "main.cpp" "${LIBS}")
install(TARGETS icescint_drs4BaselineCalibrator RUNTIME DESTINATION ${INSTALL_BIN})

# version of marek
#compile_executable(icescint_drs4BaselineCalibrator_mp "main_mp.cpp" "${LIBS}")
#install(TARGETS icescint_drs4BaselineCalibrator_mp RUNTIME DESTINATION ${INSTALL_BIN})
