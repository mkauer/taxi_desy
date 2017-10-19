########################## HESS DAQ external library support ##################
#
# similar macros as above for the hess1u libraries, but this time for the external hessdaq
# libraries
#
############################################################################### 

# register a library and its include directories so it can be used with hess1u_use_lib macro
# is only called once in common.cmake, to register a hessdaq-library
macro (hessdaq_register_lib DIR NAME)
	string(TOUPPER ${NAME} UNAME)

#   all includes are collected in a softlink directory HESSROOT/include, 
#   so no individual includes needed here... 
#	set(HESSDAQ_LIB_${UNAME}_INCLUDES ${HESSDAQ}/${DIR}/include )
	
	find_library(HESSDAQ_LIB_${UNAME}
		NAMES ${NAME} 
		PATHS ${HESSDAQ}/lib 
		NO_CMAKE_FIND_ROOT_PATH
	)
	
	message("HESSDAQLIB " ${HESSDAQ_LIB_${UNAME}})
endmacro()

# this macro is called to add the library and its include directories to the build process
# should be use in each project that needs to be compiled against a hessdaq-library
macro (hessdaq_use_lib  NAME )
	string(TOUPPER ${NAME} UNAME)
	
	if (DEFINED HESSDAQ_LIB_${UNAME}_INCLUDES) 
		include_directories(${HESSDAQ_LIB_${UNAME}_INCLUDES})
	endif()
	
	if (NOT DEFINED HESSDAQ_LIB_${UNAME}) 
		message("ERROR: using non registered library ${NAME}")
	else()
		message("DEBUG: using registered library ${NAME} : ${HESSDAQ_LIB_${UNAME}}")
	endif()
	
	set (LIBS ${HESSDAQ_LIB_${UNAME}} ${LIBS} )
	
endmacro()

# finds a library in the hessdaq library folder 
function (hessdaq_find_library NAME)
	string(TOUPPER ${NAME} UNAME)
	
	find_library(HESSDAQ_LIB_${UNAME} NAMES ${NAME} PATHS ${HESSDAQ}/lib)
	
	if (NOT HESSDAQ_LIB_${UNAME}) 
		message("ERROR: HESS DAQ library '${NAME}' not found!")
	else()
		message("HESS DAQ library '${NAME}' found: " ${HESSDAQ_LIB_${UNAME}})
	endif()
	
	set(HESSDAQ_LIB_${UNAME} ${HESSDAQ_LIB_${UNAME}} PARENT_SCOPE)
endfunction()

# define absolute path to HESS DAQ software, compiled
set(HESSDAQ $ENV{HESSROOT})

if (NOT HESSDAQ) 
	#set(HESSDAQ ${TOOLCHAIN_BASE}/hess_daq-HEAD)
	message("HESSDAQ environment variable is empty,using predefined path ${HESSDAQ}")
endif()
	
if (EXISTS "${HESSDAQ}")
	message("INFO: HESS DAQ installation found in ${HESSDAQ}")
	set(HESSDAQ-FOUND true)
else () 
	message("ERROR: HESS DAQ installation not found ${HESSDAQ}, please setup HESSDAQ environment variable correctly")	
	set(HESSDAQ-FOUND)
endif()

set(HESSDAQ_INCLUDES ${HESSDAQ}/include ${HESSDAQ}/include/idl ${HESSDAQ})

macro (use_hessdaq)
	include_directories(${HESSDAQ_INCLUDES})
endmacro()


# register sash library
hessdaq_register_lib(sash rootsash)
# register dash library
hessdaq_register_lib(trigger roottrigger)
# register dash library
hessdaq_register_lib(dash rootdash)
# register dash library
hessdaq_register_lib(hessio hessio)
# register dash library
hessdaq_register_lib(onlinetrigger onlinetrigger)

# register HESSDAQ DBTOOLS
hessdaq_find_library(stdtools)
hessdaq_find_library(simpletable)
set(HESSDAQ_LIB_DBTOOLS ${HESSDAQ_LIB_SIMPLETABLE} ${HESSDAQ_LIB_STDTOOLS})

