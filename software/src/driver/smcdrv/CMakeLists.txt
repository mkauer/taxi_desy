cmake_minimum_required(VERSION 2.6)

FILE(GLOB_RECURSE SRCC *.c )
FILE(GLOB_RECURSE SRCH *.h )

add_custom_target(
   smcdriver_all ALL
   COMMAND make OE_ROOT=${OE_ROOT}
   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
   DEPENDS ${SRCC} ${SRCH} ${INCH}
   
)

add_custom_target(
   smcdriver_clean clean
   COMMAND make clean 
   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

#Message(${PROJECT_BINARY_DIR})
#Message(${CMAKE_CURRENT_BINARY_DIR})

install(FILES smcdrv.ko DESTINATION ${INSTALL_BIN})