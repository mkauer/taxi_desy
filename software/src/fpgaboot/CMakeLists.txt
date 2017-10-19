cmake_minimum_required(VERSION 2.6)

FILE(GLOB_RECURSE SRCC *.c )
FILE(GLOB_RECURSE SRCCPP *.cpp )
set(SRC ${SRCC} ${SRCCPP})

use_library( fpgadrv LIBS)
use_library( boost LIBS)

compile_executable(fpgainit "${SRC}" "${LIBS}")
 
install(TARGETS fpgainit RUNTIME DESTINATION ${INSTALL_BIN})