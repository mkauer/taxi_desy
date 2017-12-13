# Boost c++ library setup
if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	set(BOOST_ROOT ${CMAKE_FIND_ROOT_PATH}/usr)
else()
	set(BOOST_ROOT ${CMAKE_FIND_ROOT_PATH} )
endif()

#set(Boost_NO_SYSTEM_PATHS ON)
set(Boost_DEBUG false)
set(Boost_USE_MULTITHREADED ON)	

set(Boost_ADDITIONAL_VERSIONS "1.53" "1.53.0" "1.54" "1.54.0" "1.60")
find_package(Boost 1.53 COMPONENTS atomic chrono date_time filesystem graph iostreams program_options regex random signals system thread timer)
find_package(Boost COMPONENTS chrono date_time filesystem graph program_options regex random signals system thread timer)
message(INFO ": BOOST_INCLUDEDIR = " ${Boost_INCLUDE_DIR})
#message(INFO ": BOOST_LIBRARIES = " ${Boost_LIBRARIES})

# add hess1u lib support for boost
set(HESS1U_LIB_BOOST_INCLUDES ${Boost_INCLUDE_DIR})
set(HESS1U_LIB_BOOST ${Boost_LIBRARIES})
set(HESS1U_LIBS_COMMON m)	

# add hess1u lib support for boost
set(LIB_BOOST_INCLUDES ${Boost_INCLUDE_DIR})
set(LIB_BOOST ${Boost_LIBRARIES})
set(LIBS_COMMON m)	

# register websocketpp library
set(HESS1U_LIB_WEBSOCKETPP_INCLUDES	${CMAKE_SOURCE_DIR}/common/libs/websocketpp)
# default include WEBSOCKETPP for all projects!
include_directories(${HESS1U_LIB_WEBSOCKETPP_INCLUDES})
