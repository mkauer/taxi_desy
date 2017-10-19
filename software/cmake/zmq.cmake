set(LIB_ZMQ_INCLUDES  )
find_library(LIB_ZMQ NAMES zmq)

if (NOT LIB_ZMQ)
	message("WARNING: zmq library not found")
else()
	message("INFO: zmq library found ( ${LIB_ZMQ} )")
	set(LIB_ZMQ-FOUND true)
endif()	 		
