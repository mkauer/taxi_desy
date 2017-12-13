cmake_minimum_required(VERSION 2.6)

if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	# compile for at19 only

	add_subdirectory( common )

	add_subdirectory( test_daqdrv )

	add_subdirectory( icescint_register_info )
	add_subdirectory( iceScintConfig )
	add_subdirectory( iceScintDrs4BaselineCalibrator )
	add_subdirectory( iceScintPanel )

	add_subdirectory( icescint_gpb_programmer )

	add_subdirectory( icescint_slowcontrol_server )
	add_subdirectory( icescint_slowcontrol_client )
	
else()
	# compile for x86 
	
	add_subdirectory( common )
	
	add_subdirectory( libgpb )
		
	add_subdirectory( icescint_gpb_programmer )
	add_subdirectory( icescint_gpb_client )
	add_subdirectory( test_root )
	add_subdirectory( icescint_slowcontrol_client )
	
endif()

##############################
# working with AVR toolchain #
##############################

add_subdirectory( icescint_gpb )
#add_subdirectory( icescint_gpb_bootloader )

