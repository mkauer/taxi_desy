cmake_minimum_required(VERSION 2.6)

	add_subdirectory( libcommon )


if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	add_subdirectory( driver )
	add_subdirectory( icescint )
	add_subdirectory( polarstern )

	add_subdirectory( cpuload )

	add_subdirectory( eventSender)  # generic event sender for any daqdrv readout
	add_subdirectory( eventReceiver)  # generic event receiver 
		
	add_subdirectory( smcrw )
	add_subdirectory( fpgaboot )

	add_subdirectory( install_at91 )

#	add_subdirectory( libfastcgipp )
#	add_subdirectory( httpdfcgi )

	add_subdirectory( libtaxihal )
#	add_subdirectory( ctaPower )
#	add_subdirectory( ctaRw )
	
#	add_subdirectory( polarsternEventSender )
#	add_subdirectory( polarsternEventReceiver )

	add_subdirectory( thriftExampleServer )
	
else()
	add_subdirectory( icescint )
	add_subdirectory( libtaxihal )
	add_subdirectory( eventReceiver)  # generic event receiver 
	add_subdirectory( polarstern )
endif()

