project("wordclock" C)
cmake_minimum_required(VERSION 2.6)

list(APPEND CMAKE_MODULE_PATH
    ${CMAKE_SOURCE_DIR}/cmake/vala
)
include(FindVala)
include(ValaPrecompile)

find_package(Vala "0.30" REQUIRED)


macro(make_compile_directory directory)
	if (NOT IS_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${directory}")
		make_directory("${CMAKE_CURRENT_BINARY_DIR}/${directory}")
	endif (NOT IS_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${directory}")
endmacro(make_compile_directory)

add_subdirectory(src)
