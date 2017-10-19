
#setup fastcgi library
if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)

	find_library(LIB_FCGI NAMES fcgi )
	find_library(LIB_FCGIXX NAMES fcgi++ )
#	find_library(LIB_FASTCGIPP NAMES fastcgipp )
	
	if (NOT LIB_FCGI)
		message("WARNING: fcgi library not found")
	else()
		message("INFO: fcgi library found ( ${LIB_FCGI} )")
		set(LIB_FASTCGI-FOUND true)
	endif()	 		

	if (NOT LIB_FCGIXX)
		message("WARNING: fcgi++ library not found")
	else()
		message("INFO: fcgi++ library found ( ${LIB_FCGIXX} )")
		set(LIB_FCGIXX-FOUND true)
	endif()	 		

else()

endif()

register_library( src/libfastcgipp fastcgipp)
set(LIB_FASTCGIPP_INCLUDES ${CMAKE_SOURCE_DIR}/src/libfastcgipp/include)


