project("wordclock" C)
cmake_minimum_required(VERSION 2.6)

list(APPEND CMAKE_MODULE_PATH
    ${CMAKE_SOURCE_DIR}/cmake/vala
    ${CMAKE_SOURCE_DIR}/cmake/gitrevision
)
include(FindVala)
include(ValaPrecompile)
include(GetGitRevisionDescription)

find_package(Vala "0.32" REQUIRED)

git_describe(GIT_DESCRIBE)

macro(make_compile_directory directory)
	if (NOT IS_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${directory}")
		make_directory("${CMAKE_CURRENT_BINARY_DIR}/${directory}")
	endif (NOT IS_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${directory}")
endmacro(make_compile_directory)

add_subdirectory(src)
add_subdirectory(conf)
add_subdirectory(icons)
