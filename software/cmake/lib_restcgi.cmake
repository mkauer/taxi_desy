
#setup restcgi library
if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)

	find_library(LIB_RESTCGI NAMES restcgi )
	find_library(LIB_URIPP NAMES uripp )
	
	if (NOT LIB_RESTCGI)
		message("WARNING: restcfg library not found")
	else()
		message("INFO: restcgi library found ( ${LIB_RESTCGI} )")
		set(LIB_RESTCGI-FOUND true)
	endif()	 		
	
	set(LIB_RESTCGI ${LIB_RESTCGI} ${LIB_URIPP})

else()

endif()


