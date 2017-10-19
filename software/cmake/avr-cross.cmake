SET(CMAKE_SYSTEM_NAME Generic)

if (EXISTS "/usr/avr/include" )
	set(LIB_AVR_INCLUDE "/usr/lib/avr/include" )
elseif(EXISTS "/usr/lib/avr/include" )
	set(LIB_AVR_INCLUDE /usr/avr/include)
else()	
	message("WARNING: avr include directory not found " )
endif()

SET(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")     # eliminate -rdynamic option
set( CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "" ) # eliminate -rdynamic option

message("avr include directory: ${LIB_AVR_INCLUDE}")

SET(CSTANDARD "-std=gnu99 ")
SET(CDEBUG "-gstabs -DNDEBUG")
SET(CWARN "-Wall -Wstrict-prototypes")

SET(CTUNING "-MMD -DARDUINO=156 -DARDUINO_ARCH_AVR")

# optimizations taken from http://www.tty1.net/blog/2008/avr-gcc-optimisations_en.html

#use short types
SET(CTUNING "${CTUNING} -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums" )
# dont include unused function and data
SET(CTUNING "${CTUNING} -ffunction-sections -fdata-sections")
# tell compiler that the program will never end
SET(CTUNING "${CTUNING} -ffreestanding")
# set cost of inline functions --param inline-call-cost=2
#SET(CTUNING "${CTUNING} -finline-limit=3 -fno-inline-small-functions")
# Call prologues/Epiloges, optimization for large programs
SET(CTUNING "${CTUNING} -mcall-prologues")
# whole program optimisation
#SET(CTUNING "${CTUNING} --combine-fwhole-program")
# Wide types
#SET(CTUNING "${CTUNING} -fno-split-wide-types ")
# linker relaxion
SET(CTUNING "${CTUNING} -Wl,--relax")

SET(COPT "-Os")

SET(CDEFS "-DF_CPU=3686400L")

SET(CFLAGS "${CMCU} ${CDEBUG} ${CDEFS} ${CINCS} ${COPT} ${CWARN} ${CSTANDARD} ${CEXTRA} ${CTUNING}")
SET(CXXFLAGS "${CMCU} ${CDEFS} ${CINCS} ${COPT} ${CTUNING}")

SET(CMAKE_C_FLAGS  ${CFLAGS})
SET(CMAKE_CXX_FLAGS ${CXXFLAGS})

find_program(AVR_CC avr-gcc)
find_program(AVR_CXX avr-g++)
find_program(AVR_OBJCOPY avr-objcopy)
find_program(AVR_SIZE_TOOL avr-size)
find_program(AVRDUDE avrdude)

if (AVR_CC-NOTFOUND)
	message("WARNING: avr-gcc not found")
else()
	message("found avr-gcc: ${AVR_CC}")
endif()

if (AVR_CXX-NOTFOUND)
	message("WARNING: avr-g++ not found")
else()
	message("found avr-g++: ${AVR_CXX}")
endif()

if (AVR_SIZE-NOTFOUND)
	message("WARNING: avr-size not found")
else()
	message("found avr-size: ${AVR_SIZE_TOOL}")
endif()

if (AVR_OBJCOPY-NOTFOUND)
	message("WARNING: avr-objcopy not found")
else()
	message("found avr-objcopy: ${AVR_OBJCOPY}")
endif()



set(CMAKE_C_COMPILER ${AVR_CC})
set(CMAKE_ASM_COMPILER ${AVR_CC})
set(CMAKE_CXX_COMPILER ${AVR_CXX})



set(AVR_MCU atmega128) # define a default mcu, should be overwritten by individual projects

add_definitions( -Wall )

IF(NOT CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE none CACHE STRING
      "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel."
      FORCE)
ENDIF(NOT CMAKE_BUILD_TYPE)

function(add_avr_executable EXECUTABLE_NAME SRC LIBS)

    set(elf_file ${EXECUTABLE_NAME}-${AVR_MCU}.elf)
    set(hex_file ${EXECUTABLE_NAME}-${AVR_MCU}.hex)
    set(map_file ${EXECUTABLE_NAME}-${AVR_MCU}.map)
   
    add_executable(${elf_file} EXCLUDE_FROM_ALL ${SRC})

#	message("${elf_file} use ${CFLAGS_EXTRA}")
        
    set(CMCU "-mmcu=${AVR_MCU}")
		
	set(AVR_LINK_FLAGS "${CMCU} ")

	if (NOT AVR_LDSECTION)
		message("no ld section")
	else()
		set(AVR_LINK_FLAGS "${AVR_LINK_FLAGS} ${AVR_LDSECTION}")
	endif()

	set(AVR_LINK_FLAGS "${AVR_LINK_FLAGS} -Wl,-Map,${map_file},--gc-sections")

    set_target_properties(
        ${elf_file}
        PROPERTIES
            COMPILE_FLAGS "${CMCU} ${CFLAGS_EXTRA}"
            LINK_FLAGS "${AVR_LINK_FLAGS}" 
    )

    add_custom_command(
        OUTPUT ${hex_file}
        COMMAND
##                ${AVR_OBJCOPY} -j .text -j .data -O ihex ${elf_file} ${hex_file}
            ${AVR_OBJCOPY} -O ihex -R .eeprom ${elf_file} ${hex_file}
        COMMAND
            ${AVR_SIZE_TOOL} ${elf_file}
        DEPENDS ${elf_file}
    )
    list(APPEND all_hex_files ${hex_file})
    list(APPEND all_map_files ${map_file})
        
    set(eeprom_image ${EXECUTABLE_NAME}-${AVR_MCU}-eeprom.hex)
    add_custom_command(
        OUTPUT ${eeprom_image}
        COMMAND
            ${AVR_OBJCOPY} -j .eeprom --change-section-lma .eeprom=0
                -O ihex ${elf_file} ${eeprom_image}
        DEPENDS ${elf_file}
    )
    list(APPEND all_hex_files ${eeprom_image})
    add_custom_target(
        ${EXECUTABLE_NAME}
        ALL
        DEPENDS ${all_hex_files}
    )
    get_directory_property(clean_files ADDITIONAL_MAKE_CLEAN_FILES)
    list(APPEND clean_files ${all_map_files})
    set_directory_properties(
        PROPERTIES
            ADDITIONAL_MAKE_CLEAN_FILES "${clean_files}"
    )

    set(upload_mcu ${AVR_UPLOAD_MCU})
    set(upload_file ${hex_file})
    add_custom_target(
        upload_${EXECUTABLE_NAME}
        ${AVRDUDE} -p ${upload_mcu} -c ${AVR_PROGRAMMER} ${AVRDUDE_OPTIONS}
            -U flash:w:${upload_file}
#            -U eeprom:w:${eeprom_image}
            -P usb -V -v # XXX
        DEPENDS ${upload_file} 
        COMMENT "Uploading ${upload_file} to ${upload_mcu} using programmer ${AVR_PROGRAMMER}"
    )


    add_custom_target(
        disassemble_${EXECUTABLE_NAME}
        avr-objdump -h -S ${EXECUTABLE_NAME}-${AVR_MCU}.elf > ${EXECUTABLE_NAME}.lst
        DEPENDS ${EXECUTABLE_NAME}-${AVR_MCU}.elf
    )
endfunction(add_avr_executable)

