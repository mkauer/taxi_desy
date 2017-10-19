cmake_minimum_required(VERSION 2.6)

FILE(GLOB_RECURSE SRCC *.c )
FILE(GLOB_RECURSE SRCCPP *.cpp )
set(SRC ${SRCC} ${SRCCPP})

use_library( boost LIBS )
use_library( common LIBS)

compile_executable(cpuload "${SRC}" "${LIBS}")

install(TARGETS cpuload RUNTIME DESTINATION ${INSTALL_BIN})