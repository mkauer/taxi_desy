# find poco library

set(HESS1U_LIB_POCO_INCLUDES  )		
find_library(HESS1U_LIB_POCO_NET NAMES PocoNet)
set(HESS1U_LIB_POCO ${HESS1U_LIB_POCO_NET})

if (NOT HESS1U_LIB_POCO_NET)
	message("WARNING: poco net library not found")
else()
	message("INFO: poco net library found ( ${HESS1U_LIB_POCO_NET} ${HESS1U_LIB_POCO_INCLUDES} )")
	set(HESS1U_LIB_POCO-FOUND true)
endif()	 		
