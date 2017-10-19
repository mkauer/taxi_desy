cmake_minimum_required(VERSION 2.6)

FILE(GLOB_RECURSE SRC src/*.cpp )

include_directories( include )

compile_library(fastcgipp "${SRC}" "") 

install_library(fastcgipp)
