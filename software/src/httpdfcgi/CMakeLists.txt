cmake_minimum_required(VERSION 2.6)

use_library(boost LIBS)
use_library(fcgixx LIBS)
use_library(fastcgipp LIBS)

compile_executable(echo.fcgi "echo.cpp" "${LIBS}")
install(TARGETS echo.fcgi RUNTIME DESTINATION bin)	

use_library(smcdrv LIBS)

compile_executable(status.fcgi "status.cpp" "${LIBS}")
install(TARGETS status.fcgi RUNTIME DESTINATION bin)	

#compile_executable(i4csvexport.fcgi "csvexport.cpp" "${LIBS}")
#install(TARGETS i4csvexport.fcgi RUNTIME DESTINATION bin)	

#compile_executable(i4rest.fcgi "rest.cpp" "${LIBS}")
#install(TARGETS i4rest.fcgi RUNTIME DESTINATION bin)	

#compile_executable(i4metrics.fcgi "metrics.cpp" "${LIBS}")
#install(TARGETS i4metrics.fcgi RUNTIME DESTINATION bin)	

install(FILES lighttpd.conf DESTINATION bin )

