

if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	find_library(HESS1U_LIB_PROCPS NAMES proc-3.2.8)
	set(HESS1U_LIB_PROCPS_INCLUDES $ENV{OE_ROOT}/tmp-eglibc/work/armv5te-oe-linux-gnueabi/procps/3.2.8-r11/procps-3.2.8)
else()
	find_library(HESS1U_LIB_PROCPS NAMES proc )
endif()

# message("HESS1U_LIB_PROCPS_INCLUDES ${HESS1U_LIB_PROCPS_INCLUDES}")

if (NOT HESS1U_LIB_PROCPS)
	message("WARNING: proc library not found")
else()
	message("INFO: proc library found ( ${HESS1U_LIB_PROCPS} )")
	set(HESS1U_LIB_PROCPS-FOUND true)
endif()	 		
