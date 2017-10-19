cmake_minimum_required(VERSION 2.6)

#use_library( taxihal LIBS )
use_library( boost LIBS)
use_library( thrift LIBS)
#use_library( glog LIBS)
use_library( icescint_common LIBS)

FILE(GLOB_RECURSE SRCC *.c )
FILE(GLOB_RECURSE SRCCPP *.cpp )
set(SRC ${SRCC} ${SRCCPP})

compile_executable(icescint_slowcontrol_client "${SRC}" "${LIBS}")

install(TARGETS icescint_slowcontrol_client RUNTIME DESTINATION ${INSTALL_BIN})
