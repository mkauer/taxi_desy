cmake_minimum_required(VERSION 2.6)

use_library( taxihal LIBS )
use_library( smcdrv LIBS )


FILE(GLOB_RECURSE SRCC *.c )
FILE(GLOB_RECURSE SRCCPP *.cpp )
SET(SRC ${SRCC} ${SRCCPP})

include_directories( . )

compile_library(icescint_gpb "${SRC}" "${LIBS}") 

#target_link_libraries(icescint_gpb ${LIBS})

install_library(icescint_gpb)
