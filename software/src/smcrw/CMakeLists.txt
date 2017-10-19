cmake_minimum_required(VERSION 2.6)

FILE(GLOB_RECURSE SRCC *.c )
FILE(GLOB_RECURSE SRCCPP *.cpp )
set(SRC ${SRCC} ${SRCCPP})

use_library( smcdrv LIBS )
use_library( boost LIBS )

compile_executable(smcrw "${SRC}" "${LIBS}")
 
install(TARGETS smcrw RUNTIME DESTINATION ${INSTALL_BIN})