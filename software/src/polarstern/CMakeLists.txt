cmake_minimum_required(VERSION 2.6)

if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	# compile for at19 only

	add_subdirectory( polarsternEventSender )
	add_subdirectory( polarsternEventReceiver )

else()
	# compile for x86 
	
	add_subdirectory( polarsternEventReceiver )
		
endif()


