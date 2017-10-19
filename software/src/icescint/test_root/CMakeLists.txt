cmake_minimum_required(VERSION 2.6)

set (SRC_CLIENT test.cpp )

include_directories( . )


if (ROOT_LIB_CINT) 
	
	use_library(boost LIBS)
	use_library(root LIBS)

	compile_executable (baselineRoiAnalyser "baselineRoiAnalyser.cpp" "${LIBS}")
	compile_executable (test_histogram "testHistogram.cpp" "${LIBS}")

	compile_executable (test_correlation "testCorrelation.cpp" "${LIBS}")

endif()