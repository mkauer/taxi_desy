# find ncurses library

if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	# at91 variant
	find_library(NCURSES_LIB NAMES ncurses )
	
	if (NOT NCURSES_LIB)
		message("WARNING: ncursesw library not found")
	else()
		message("INFO: ncursesw library found ( ${NCURSES_LIB} )")
	endif()	 		
	
	find_library(CDK_LIB NAMES cdk )
	
	if (NOT CDK_LIB)
		message("WARNING: cdk library not found")
	else()
		message("INFO: cdk library found ( ${CDK_LIB} )")
	endif()	 		
	
	find_library(PANEL_LIB NAMES panel)
	if (NOT PANEL_LIB)
		message("WARNING: panel library not found")
	else()
		message("INFO: panel library found ( ${PANEL_LIB} )")
	endif()	 		
	
	find_library(MENU_LIB NAMES menu)
	if (NOT MENU_LIB)
		message("WARNING: menu library not found")
	else()
		message("INFO: menu library found ( ${MENU_LIB} )")
	endif()	 		

	find_library(FORM_LIB NAMES form)
	if (NOT FORM_LIB)
		message("WARNING: form library not found")
	else()
		message("INFO: form library found ( ${FORM_LIB} )")
	endif()	 		
	
	set(HESS1U_LIB_NCURSES_INCLUDEDIR )
	set(HESS1U_LIB_NCURSES ${NCURSES_LIB} ${PANEL_LIB} ${MENU_LIB} ${FORM_LIB} )

else()
	# x86 variant
	find_library(NCURSES_LIB NAMES ncursesw )
	
	if (NOT NCURSES_LIB)
		message("WARNING: ncursesw library not found")
	else()
		message("INFO: ncursesw library found ( ${NCURSES_LIB} )")
	endif()	 		
	
	find_library(CDK_LIB NAMES cdk )
	
	if (NOT CDK_LIB)
		message("WARNING: cdk library not found")
	else()
		message("INFO: cdk library found ( ${CDK_LIB} )")
	endif()	 		
	
	find_library(PANEL_LIB NAMES panel)
	if (NOT PANEL_LIB)
		message("WARNING: panel library not found")
	else()
		message("INFO: panel library found ( ${PANEL_LIB} )")
	endif()	 		
	
	find_library(MENU_LIB NAMES menu)
	if (NOT MENU_LIB)
		message("WARNING: menu library not found")
	else()
		message("INFO: menu library found ( ${MENU_LIB} )")
	endif()	 		

	find_library(FORM_LIB NAMES form)
	if (NOT FORM_LIB)
		message("WARNING: form library not found")
	else()
		message("INFO: form library found ( ${FORM_LIB} )")
	endif()	 		
	
	set(HESS1U_LIB_NCURSES_INCLUDEDIR )
	set(HESS1U_LIB_NCURSES ${NCURSES_LIB} ${PANEL_LIB} ${MENU_LIB} ${FORM_LIB} )
	set(HESS1U_LIB_CDK ${CDK_LIB} )
endif()