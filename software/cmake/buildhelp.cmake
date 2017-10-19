###############################################################################
# Macro definitions for libraries and executables
# --------------------------------------------------------
# For each library the include path and the library path are stored in variables:
#   LIB_<name>           - Library to use for linking with library <name>
#   LIB_<name>_STATIC    - static library to use for linking with library <name>
#   LIB_<name>_SHARED    - shared library to use for dynamic linking with library <name>
#   LIB_<name>_INCLUDES  - Include directory to add to include paths
#
#   use macros hess1u_add_lib, hess1u_register_lib to setup the environment variables within this file  
#   use macro hess1u_use_lib to compile against a library   
# 
###############################################################################

set(INSTALL_BIN bin)
set(INSTALL_LIB lib)

function(require_environment_variable NAME)

	if ("$ENV{${NAME}} " STREQUAL " ") 
	  message( FATAL_ERROR "Environment Variable ${NAME} is empty or not defined" )
	else()	
	  message("INFO checking Environment Variable ${NAME} = '$ENV{${NAME}}' - OK")
	endif()	
endfunction()

function(require_directory NAME)
	if (IS_DIRECTORY ${NAME}) 
	  message( FATAL_ERROR "checking directory exists ${NAME} - FAIL")
	else()	
	  message("INFO checking directory exists ${NAME} - OK")	
	endif()	
endfunction()

# this macro is called to add the library and it includes directories to the build process
function(use_library NAME LIBNAMES)
    set(${LIBNAMES} ${NAME} ${${LIBNAMES}} PARENT_SCOPE)
	string(TOUPPER ${NAME} UNAME)
	
	# add includes to include path (must be done here to avoid multiple inclusions)
	include_directories( ${LIB_${UNAME}_INCLUDES} )


#	set (EXTRA_LIBS 
#		${LIB_${UNAME}}
#		${EXTRA_LIBS} 
#	)
#	set (COMPILE_DEFINITIONS 
#		${LIB_${UNAME}_DEFINITIONS}
#		${COMPILE_DEFINITIONS} 
#	)

#	message("Using Library ${NAME} using includes ${DESY_LIB_${UNAME}_INCLUDES}")
	
endfunction()

# creates an library target that gets compiled with common libraries and extra libraries
# should be used only once for each library in the CMakeLists.txt where it is compiled 
function (compile_library NAME SOURCES LIBLIST)
	string(TOUPPER ${NAME} UNAME)
	
	if (DEFINED LIB_${UNAME})
	else()	
		MESSAGE("ERROR: library '${UNAME}' used but not registered, LIB_${UNAME} = '${LIB_${UNAME}}'")
	endif()
		
	add_library (${LIB_${UNAME}_SHARED} SHARED ${SOURCES})
	add_library (${LIB_${UNAME}_STATIC} STATIC ${SOURCES})
		
	set(COMPILE_DEFINITIONS)
	
	# collect all definitions
	foreach(LIBNAME ${LIBLIST})
		string(TOUPPER ${LIBNAME} UNAME)
		set(COMPILE_DEFINITIONS ${COMPILE_DEFINITIONS} ${LIB_${UNAME}_DEFINITIONS})	
		#essage("lib ${NAME} uses lib ${LIBNAME} with def ${LIB_${UNAME}_DEFINITIONS}")
	endforeach()

	string(TOUPPER ${NAME} UNAME)

	foreach(f ${COMPILE_DEFINITIONS})
		set_property(
			TARGET ${LIB_${UNAME}_SHARED}
		    PROPERTY COMPILE_DEFINITIONS ${f}
		)
		set_property(
			TARGET ${LIB_${UNAME}_STATIC}
		    PROPERTY COMPILE_DEFINITIONS ${f}
		)
#		set_property(
#			TARGET ${NAME}
#		    PROPERTY COMPILE_DEFINITIONS ${f}
#		)
		#message("Adding Definitions: ${UNAME} " ${f} " for " ${UNAME})
	endforeach(f)	

		
endfunction()

# creates an library target that gets compiled with common libraries and extra libraries
# should be used only once for each library in the CMakeLists.txt where it is compiled 
function (compile_shared_library NAME SOURCES LIBLIST)
	string(TOUPPER ${NAME} UNAME)
	
	if (DEFINED LIB_${UNAME})
	else()	
		MESSAGE("ERROR: library '${UNAME}' used but not registered, LIB_${UNAME} = '${LIB_${UNAME}}'")
	endif()
		
	add_library (${LIB_${UNAME}_SHARED} SHARED ${SOURCES})
		
	set(COMPILE_DEFINITIONS)
	
	# collect all definitions
	foreach(LIBNAME ${LIBLIST})
		string(TOUPPER ${LIBNAME} UNAME)
		set(COMPILE_DEFINITIONS ${COMPILE_DEFINITIONS} ${LIB_${UNAME}_DEFINITIONS})	
		#essage("lib ${NAME} uses lib ${LIBNAME} with def ${LIB_${UNAME}_DEFINITIONS}")
	endforeach()

	string(TOUPPER ${NAME} UNAME)

	foreach(f ${COMPILE_DEFINITIONS})
		set_property(
			TARGET ${LIB_${UNAME}_SHARED}
		    PROPERTY COMPILE_DEFINITIONS ${f}
		)
		set_property(
			TARGET ${LIB_${UNAME}_STATIC}
		    PROPERTY COMPILE_DEFINITIONS ${f}
		)
#		set_property(
#			TARGET ${NAME}
#		    PROPERTY COMPILE_DEFINITIONS ${f}
#		)
		#message("Adding Definitions: ${UNAME} " ${f} " for " ${UNAME})
	endforeach(f)	

		
endfunction()

function (install_library NAME)
	string(TOUPPER ${NAME} UNAME)
	install (TARGETS ${LIB_${UNAME}_SHARED} LIBRARY DESTINATION ${INSTALL_LIB})
endfunction()

function (install_executable NAME)
	install (TARGETS ${NAME} RUNTIME DESTINATION ${INSTALL_BIN})
endfunction()

# creates an executable target that gets compiled with common libraries and extra libaries
# should be used only once for each executable in the CMakeLists.txt where it is compiled 
function (compile_executable NAME SOURCES LIBLIST)
		
	add_executable(${NAME} ${SOURCES})

	set(COMPILE_DEFINITIONS)
	set(LIBS "")

	# collect all definitions
	foreach(LIBNAME ${LIBLIST})
		string(TOUPPER ${LIBNAME} ULIBNAME)
		
		# check if library is correctly registered
		if (DEFINED LIB_${ULIBNAME})
		   set(COMPILE_DEFINITIONS ${COMPILE_DEFINITIONS} ${LIB_${ULIBNAME}_DEFINITIONS})	
		   set(LIBS ${LIBS} ${LIB_${ULIBNAME}})
		else()	
		   set(LIBS ${LIBS} ${LIBNAME})
			#MESSAGE("ERROR: library '${LIBNAME}' used but not registered, LIB_${ULIBNAME} = '${LIB_${ULIBNAME}}'")
		endif()
	
		
		#MESSAGE("INFO: ${NAME} adding library '${LIBNAME}', includes = '${LIB_${ULIBNAME}_INCLUDES}'")
				
	endforeach()

	#MESSAGE("INFO: linking with libraries '${LIBS}'")

	target_link_libraries (${NAME} ${LIBS})
		
	foreach(f ${COMPILE_DEFINITIONS})
		set_property(
			TARGET ${NAME}
		    PROPERTY COMPILE_DEFINITIONS ${f}
		)
		#message("Adding Definitions: ${NAME} " ${f} " for " ${NAME})
	endforeach(f)	
	
endfunction()


# register a library and its include directories so it can be used
# is only called once in common.cmake, to register a library
macro (register_library DIR NAME)
	string(TOUPPER ${NAME} UNAME)

	set(LIB_${UNAME}_INCLUDES ${CMAKE_SOURCE_DIR}/${DIR} )
	set(LIB_${UNAME}_STATIC ${NAME}_static )
	set(LIB_${UNAME}_SHARED ${NAME} )
	set(LIB_${UNAME} ${LIB_${UNAME}_SHARED} )	# default option
endmacro() 
