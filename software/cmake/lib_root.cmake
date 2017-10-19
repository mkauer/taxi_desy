
# ******************* setup root library
  
if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)

else()
    if ("$ENV{ROOTSYS}" STREQUAL "")
            message("ATTENTION! Build without ROOT, forgot to setup ROOTSYS environment variable?")
    else()
            message(INFO " Environment Variable ROOTSYS is defined: building with ROOT")
            require_directory(ROOTSYS)

            set(ROOT_ENABLE true)
            include(cmake/FindROOT.cmake)
    endif()
	
	find_library(ROOT_LIB_CORE Core PATHS ${ROOT_LIBRARY_DIR})
	find_library(ROOT_LIB_TREE Tree PATHS ${ROOT_LIBRARY_DIR})
	find_library(ROOT_LIB_CINT Cint PATHS ${ROOT_LIBRARY_DIR})
	find_library(ROOT_LIB_HIST Hist PATHS ${ROOT_LIBRARY_DIR})
	find_library(ROOT_LIB_RIO RIO PATHS ${ROOT_LIBRARY_DIR})
	find_library(ROOT_LIB_NET Net PATHS ${ROOT_LIBRARY_DIR})
	find_library(ROOT_LIB_HIST Hist PATHS ${ROOT_LIBRARY_DIR})
	find_library(ROOT_LIB_TREE Tree PATHS ${ROOT_LIBRARY_DIR})
	find_library(ROOT_LIB_RINT Rint PATHS ${ROOT_LIBRARY_DIR})
	find_library(ROOT_LIB_TREE Thread PATHS ${ROOT_LIBRARY_DIR})
	
	set(ROOT_LIBS ${ROOT_LIB_CORE} ${ROOT_LIB_TREE} ${ROOT_LIB_CINT} ${ROOT_LIB_HIST} ${ROOT_LIB_RIO} ${ROOT_LIB_NET} ${ROOT_LIB_HIST} ${ROOT_LIB_TREE} ${ROOT_LIB_RINT} ${ROOT_LIB_TREE} )

	set(LIB_ROOT ${ROOT_LIBS})
	set(LIB_ROOT_INCLUDES ${ROOT_INCLUDE_DIR})
	
endif()

