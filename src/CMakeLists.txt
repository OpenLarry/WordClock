find_package(PkgConfig)
pkg_check_modules(GOBJECT REQUIRED gobject-2.0)
pkg_check_modules(LIBSOUP REQUIRED libsoup-2.4)
pkg_check_modules(GIO_UNIX REQUIRED gio-unix-2.0)
pkg_check_modules(GIO REQUIRED gio-2.0)
pkg_check_modules(GEE REQUIRED gee-0.8)
pkg_check_modules(JSON_GLIB REQUIRED json-glib-1.0)

set(CFLAGS
	${GOBJECT_CFLAGS} ${GOBJECT_CFLAGS_OTHER}
	${LIBSOUP_CFLAGS} ${LIBSOUP_CFLAGS_OTHER}
	${GIO_UNIX_CFLAGS} ${GIO_UNIX_CFLAGS_OTHER}
	${GIO_CFLAGS} ${GIO_CFLAGS_OTHER}
	${GEE_CFLAGS} ${GEE_OTHER}
	${JSON_GLIB_CFLAGS} ${JSON_GLIB_OTHER}
)
add_definitions(${CFLAGS})

set(LIBS
	${GOBJECT_LIBRARIES}
	${LIBSOUP_LIBRARIES}
	${GIO_UNIX_LIBRARIES}
	${GIO_LIBRARIES}
	${GEE_LIBRARIES}
	${JSON_GLIB_LIBRARIES}
)
link_libraries(${LIBS})

set(LIB_PATHS
	${GOBJECT_LIBRARY_DIRS}
	${LIBSOUP_LIBRARY_DIRS}
	${GIO_UNIX_LIBRARY_DIRS}
	${GIO_LIBRARY_DIRS}
	${GEE_LIBRARY_DIRS}
	${JSON_GLIB_LIBRARY_DIRS}
)
link_directories(${LIB_PATHS})

set(VALA_SRC
	Main.vala
	RestServer.vala
	Color.vala
	Lirc.vala
	Buzzer.vala
	Settings.vala
	SettingsBindable.vala
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
	Renderer/StringRenderer.vala
	Renderer/StringRendererFont.vala
	Renderer/StringRendererMicrosoftSansSerif.vala
	Renderer/StringRendererConsolas.vala
	Sensors/Lradc.vala
	Sensors/Sensors.vala
	Sensors/Gpio.vala
)


vala_precompile(VALA_C
	${VALA_SRC}
PACKAGES 
	libsoup-2.4
	gio-unix-2.0
	gio-2.0
	gee-0.8
	json-glib-1.0
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

add_definitions(-w)

# explicitly add libraries (needed e.g. for Fedora 13+)
target_link_libraries(wordclock -lm)

install(TARGETS 
	wordclock
RUNTIME
DESTINATION
	bin
)
