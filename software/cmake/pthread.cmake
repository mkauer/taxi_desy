set(LIB_PTHREAD  )		
set(LIB_PTHREAD_INCLUDES  )		
find_library(LIB_PTHREAD NAMES pthread)

if (NOT LIB_PTHREAD)
	message("WARNING: pthread library not found")
else()
	message("INFO: pthread library library found ( ${HESS1U_LIB_PTHREAD} )")
	set(HESS1U_LIB_PTHREAD-FOUND true)
endif()	 		

