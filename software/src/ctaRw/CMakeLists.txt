cmake_minimum_required(VERSION 2.6)

include_directories( . )

use_library(boost LIBS)
use_library(smcdrv LIBS)
use_library(taxihal LIBS)

compile_executable(cta_rw "main.cpp" "${LIBS}")
install(TARGETS cta_rw RUNTIME DESTINATION bin)	
 
