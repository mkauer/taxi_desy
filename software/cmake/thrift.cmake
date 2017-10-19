#setup thrift  library
set(IB_THRIFT_INCLUDES  )
set(LIB_THRIFT_DEFINITIONS HAVE_CONFIG_H)


if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	
else()
	# finds a local installed config.h in the thrift include path, which is needed for thrift include files to compile
	if (EXISTS "$ENV{TOOLCHAIN_LOCAL}/include/thrift/")
		find_path(LIB_THRIFT_INCLUDES config.h PATHS $ENV{TOOLCHAIN_LOCAL}/include/thrift)
	endif()
		
endif()

message("INFO: thrift includes: ${LIB_THRIFT_INCLUDES}")

find_library(LIB_THRIFT NAMES thrift)

if (NOT LIB_THRIFT)
	message("WARNING: thrift library not found")
else()
	message("INFO: thrift library found ( ${LIB_THRIFT} )")
	set(LIB_THRIFT-FOUND true)
endif()	 		

# helper function to generate thrift code
function(thrift_generate SRCOUT FILE)
    GET_FILENAME_COMPONENT(NAME ${FILE} NAME_WE)
    
    GET_FILENAME_COMPONENT(FILEPATH ${FILE} PATH)

    set(THRIFT_CONSTANTS_SRC ${FILEPATH}/gen-cpp/${NAME}_constants.cpp ${FILEPATH}/gen-cpp/${NAME}_constants.h)

	file(STRINGS ${FILE} thriftfile)
	
	foreach(line in ${thriftfile})
	if(line MATCHES "^(struct|enum|include) *")
    	set(THRIFT_TYPES_SRC ${FILEPATH}/gen-cpp/${NAME}_types.cpp ${FILEPATH}/gen-cpp/${NAME}_types.h)
    endif()
	if(line MATCHES "^service ([^ ]*) ")
		list(APPEND THRIFT_SERVICES_SRC ${FILEPATH}/gen-cpp/${CMAKE_MATCH_1}.cpp ${FILEPATH}/gen-cpp/${CMAKE_MATCH_1}.h)
	endif()
	endforeach(line)
	

    set(THRIFT_SRCOUT ${THRIFT_CONSTANTS_SRC} ${THRIFT_TYPES_SRC} ${THRIFT_SERVICES_SRC})
    list(APPEND ${SRCOUT} ${THRIFT_SRCOUT})

	add_custom_command(
	OUTPUT 
    	${THRIFT_SRCOUT}
	COMMAND
    	thrift --gen cpp --gen py --gen js:jquery ${FILE}
	DEPENDS 
    	${FILE}
    WORKING_DIRECTORY
    	${FILEPATH}
	)

	set(${SRCOUT} ${THRIFT_SRC} PARENT_SCOPE)
endfunction()
