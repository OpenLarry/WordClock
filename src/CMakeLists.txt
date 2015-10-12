find_package(PkgConfig)
pkg_check_modules(GOBJECT REQUIRED gobject-2.0)
pkg_check_modules(LIBSOUP REQUIRED libsoup-2.4)
pkg_check_modules(GIO_UNIX REQUIRED gio-unix-2.0)
pkg_check_modules(GEE REQUIRED gee-1.0)

set(CFLAGS
	${GOBJECT_CFLAGS} ${GOBJECT_CFLAGS_OTHER}
	${LIBSOUP_CFLAGS} ${LIBSOUP_CFLAGS_OTHER}
	${GIO_UNIX_CFLAGS} ${GIO_CFLAGS_OTHER}
	${GEE_CFLAGS} ${GEE_OTHER}
)
add_definitions(${CFLAGS})

set(LIBS
	${GOBJECT_LIBRARIES}
	${LIBSOUP_LIBRARIES}
	${GIO_UNIX_LIBRARIES}
	${GEE_LIBRARIES}
)
link_libraries(${LIBS})

set(LIB_PATHS
	${GOBJECT_LIBRARY_DIRS}
	${LIBSOUP_LIBRARY_DIRS}
	${GIO_UNIX_LIBRARY_DIRS}
	${GEE_LIBRARY_DIRS}
)
link_directories(${LIB_PATHS})

set(VALA_SRC
	Main.vala
	RestServer.vala
	Color.vala
	Lirc.vala
	Buzzer.vala
	Driver/LedDriver.vala
	Driver/Ws2812bDriver.vala
	Wiring/ClockWiring.vala
	Wiring/MarkusClockWiring.vala
	FrontPanel/FrontPanel.vala
	FrontPanel/GermanFrontPanel.vala
	FrontPanel/RhineRuhrGermanFrontPanel.vala
	FrontPanel/WestGermanFrontPanel.vala
	FrontPanel/EastGermanFrontPanel.vala
	Renderer/FrameRenderer.vala
	Renderer/ClockRenderable.vala
	Renderer/ClockRenderer.vala
	Renderer/MatrixRenderer.vala
	Renderer/DotsRenderer.vala
	Renderer/BacklightRenderer.vala
	Renderer/TimeRenderer.vala
	Renderer/SecondsRenderer.vala
	Renderer/BigTimeRenderer.vala
	Renderer/TestSequenceRenderer.vala
	Renderer/ColorRenderer.vala
)

# Vala segfaults if its output dirs are not existant. Therefore make sure they
# are there.
macro(make_compile_directory directory)
	if (NOT IS_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${directory}")
		make_directory("${CMAKE_CURRENT_BINARY_DIR}/${directory}")
	endif (NOT IS_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${directory}")
endmacro(make_compile_directory)

vala_precompile(VALA_C
	${VALA_SRC}
PACKAGES 
	libsoup-2.4
	gio-unix-2.0
	gee-1.0
#	poppler-glib
#	gtk+-2.0
	posix
	linux
OPTIONS 
	--thread
	--target-glib 2.42
#	--debug
#GENERATE_HEADER
#	wordclock
#GENERATE_VAPI
#	wordclock
)

add_executable(wordclock
  	${VALA_C}
)

# explicitly add libraries (needed e.g. for Fedora 13+)
target_link_libraries(wordclock -lm)

install(TARGETS 
	wordclock
RUNTIME
DESTINATION
	bin
)
