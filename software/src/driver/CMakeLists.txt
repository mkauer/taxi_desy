cmake_minimum_required(VERSION 2.6)


if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	add_subdirectory( smcdrv )
	add_subdirectory( fpgadrv )
	add_subdirectory( daqdrv )

	add_subdirectory( libsmcdrv )   # support library for the driver for smc bus access
	add_subdirectory( libfpgadrv )  # support library for the driver for loading fpga
	add_subdirectory( libdaqdrv )	# support library for the driver for irq driven fifo readout

endif()

