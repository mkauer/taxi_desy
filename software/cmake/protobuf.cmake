# find protobuf library

set(HESS1U_LIB_PROTOBUF_INCLUDES  )		
find_library(HESS1U_LIB_PROTOBUF NAMES protobuf)

if (NOT HESS1U_LIB_PROTOBUF)
	message("WARNING: protocol buffer library not found")
else()
	message("INFO: protocol buffer library found ( ${HESS1U_LIB_PROTOBUF} ${HESS1U_LIB_PROTOBUF_INCLUDES} )")
	set(HESS1U_LIB_PROTOBUF-FOUND true)
endif()	 		

set(PROTOC protoc)

function(protobuf_generate SRCOUT FILE)    

# Generates the c++ code into the binary directory
# and copies files, if changed into source dir
# 
# ISSUE: 
#   if in the project exists a *.proto file with duplicate name, it will override the file of each other

    GET_FILENAME_COMPONENT(NAME ${FILE} NAME_WE)

    GET_FILENAME_COMPONENT(FILEPATH ${FILE} PATH)

    set(SRCBIN ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.pb.cc ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.pb.h)
    
    set(SRC ${FILEPATH}/${NAME}.pb.cc ${FILEPATH}/${NAME}.pb.h)

    message("INFO: generate protobuf " ${FILE} )

    add_custom_command(
        OUTPUT 
            ${SRCBIN}          
        COMMAND
            ${PROTOC} --python_out=${FILEPATH} --cpp_out=${CMAKE_CURRENT_BINARY_DIR} ${FILE} -I ${FILEPATH}
        DEPENDS 
            ${FILE}
    )
    
    add_custom_command(
    	OUTPUT ${FILEPATH}/${NAME}.pb.cc
    	COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.pb.cc ${FILEPATH}/${NAME}.pb.cc 
    	MAIN_DEPENDENCY ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.pb.cc
    )

    add_custom_command(
    	OUTPUT ${FILEPATH}/${NAME}.pb.h
    	COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.pb.h ${FILEPATH}/${NAME}.pb.h 
    	MAIN_DEPENDENCY ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.pb.h
    )

    set(${SRCOUT} ${SRC} PARENT_SCOPE)
    
endfunction()  

