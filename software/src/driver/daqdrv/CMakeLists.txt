cmake_minimum_required(VERSION 2.6)

include_directories(  )

FILE(GLOB_RECURSE SRCC *.c )
FILE(GLOB_RECURSE SRCH *.h )
FILE(GLOB_RECURSE INCH ${CMAKE_SOURCE_DIR}/src/driver/libdaqdrv/hal/*.h )

add_custom_target(
   daqdriver_all 
   COMMAND make -f ${CMAKE_CURRENT_SOURCE_DIR}/Makefile OE_ROOT=${OE_ROOT} INCLUDE_HAL=${CMAKE_SOURCE_DIR}/src/driver/libdaqdrv/hal MODULE_SOURCE=${CMAKE_CURRENT_SOURCE_DIR} 
   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
   DEPENDS ${SRCC} ${SRCH} ${INCH}
)

add_custom_target(
   daqdriver_clean
   COMMAND make -f ${CMAKE_CURRENT_SOURCE_DIR}/Makefile clean MODULE_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}
   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

Message(${PROJECT_BINARY_DIR})
Message(${CMAKE_CURRENT_BINARY_DIR})

install(FILES daqdrv.ko DESTINATION ${INSTALL_BIN})