cmake_minimum_required(VERSION 2.6)

FILE(GLOB_RECURSE SRCC *.c )
FILE(GLOB_RECURSE SRCCPP *.cpp )
SET(SRC ${SRCC} ${SRCCPP})

include_directories( . )

use_library( smcdrv LIBS )

compile_library(taxihal "${SRC}" "") 

install_library(taxihal)

