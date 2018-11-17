cmake_minimum_required(VERSION 2.6)

if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	# compile for at19 only

#	add_subdirectory( common )
	add_subdirectory( uvlogger_debugger )
	add_subdirectory( uvlogger_config )
	add_subdirectory( uvlogger_ledtune )
	add_subdirectory( uvlogger_rates )
	
else()
	# compile for x86 
		
endif()


