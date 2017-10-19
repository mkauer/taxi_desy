#setup google logging library glog
set(HESS1U_LIB_GLOG_INCLUDES  )		
find_library(HESS1U_LIB_GLOG NAMES glog)

if (NOT HESS1U_LIB_GLOG)
	message("WARNING: glog library not found")
else()
	message("INFO: glog library library found ( ${HESS1U_LIB_GLOG} )")
	set(HESS1U_LIB_GLOG-FOUND true)
endif()	 		
