project("wordclock" C)
cmake_minimum_required(VERSION 2.6)

list(APPEND CMAKE_MODULE_PATH
    ${CMAKE_SOURCE_DIR}/cmake/vala
)
include(UseVala)
include(FindVala)

find_package(Vala "0.30" REQUIRED)

add_subdirectory(src)

