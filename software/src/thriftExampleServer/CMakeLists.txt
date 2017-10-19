cmake_minimum_required(VERSION 2.6)

use_library(boost LIBS)
use_library(thrift LIBS)

#FILE(GLOB_RECURSE SRC *.cpp)

thrift_generate(THRIFT_SRC ${CMAKE_CURRENT_SOURCE_DIR}/example.thrift)

set(SRC main.cpp ${THRIFT_SRC})

compile_executable(thriftExampleServer "${SRC}" "${LIBS}")

