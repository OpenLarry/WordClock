find_package(PkgConfig)
pkg_check_modules(GOBJECT REQUIRED gobject-2.0)
pkg_check_modules(LIBSOUP REQUIRED libsoup-2.4)
pkg_check_modules(GIO_UNIX REQUIRED gio-unix-2.0)
pkg_check_modules(GIO REQUIRED gio-2.0)
pkg_check_modules(GEE REQUIRED gee-0.8)
pkg_check_modules(JSON_GLIB REQUIRED json-glib-1.0)
pkg_check_modules(LUAJIT REQUIRED luajit)
pkg_check_modules(CAIRO REQUIRED cairo)
pkg_check_modules(PANGO REQUIRED pango)
pkg_check_modules(PANGOCAIRO REQUIRED pangocairo)

set(CFLAGS
	${GOBJECT_CFLAGS} ${GOBJECT_CFLAGS_OTHER}
	${LIBSOUP_CFLAGS} ${LIBSOUP_CFLAGS_OTHER}
	${GIO_UNIX_CFLAGS} ${GIO_UNIX_CFLAGS_OTHER}
	${GIO_CFLAGS} ${GIO_CFLAGS_OTHER}
	${GEE_CFLAGS} ${GEE_OTHER}
	${JSON_GLIB_CFLAGS} ${JSON_GLIB_OTHER}
	${LUAJIT_CFLAGS} ${LUAJIT_OTHER}
	${CAIRO_CFLAGS} ${CAIRO_OTHER}
	${PANGO_CFLAGS} ${PANGO_OTHER}
	${PANGOCAIRO_CFLAGS} ${PANGOCAIRO_OTHER}
)
add_definitions(${CFLAGS})

set(LIBS
	${GOBJECT_LIBRARIES}
	${LIBSOUP_LIBRARIES}
	${GIO_UNIX_LIBRARIES}
	${GIO_LIBRARIES}
	${GEE_LIBRARIES}
	${JSON_GLIB_LIBRARIES}
	${LUAJIT_LIBRARIES}
	${CAIRO_LIBRARIES}
	${PANGO_LIBRARIES}
	${PANGOCAIRO_LIBRARIES}
	-lwpa_client
)
link_libraries(${LIBS})

set(LIB_PATHS
	${GOBJECT_LIBRARY_DIRS}
	${LIBSOUP_LIBRARY_DIRS}
	${GIO_UNIX_LIBRARY_DIRS}
	${GIO_LIBRARY_DIRS}
	${GEE_LIBRARY_DIRS}
	${JSON_GLIB_LIBRARY_DIRS}
	${LUAJIT_LIBRARY_DIRS}
	${CAIRO_LIBRARY_DIRS}
	${PANGO_LIBRARY_DIRS}
	${PANGOCAIRO_LIBRARY_DIRS}
)
link_directories(${LIB_PATHS})


configure_file("${CMAKE_CURRENT_SOURCE_DIR}/Version.vala.in" "${CMAKE_CURRENT_SOURCE_DIR}/Version.vala" @ONLY)

set(VALA_SRC
	Main.vala
	RestServer.vala
	Settings.vala
	SettingsMigrator.vala
	Lua/Lua.vala
	Lua/LuaSignals.vala
	Lua/LuaSettings.vala
	Lua/LuaMessage.vala
	Lua/LuaImage.vala
	Lua/LuaBuzzer.vala
	Lua/LuaSink.vala
	Lua/LuaHwinfo.vala
	Color/Color.vala
	Color/HueRotateColor.vala
	Color/BrightnessSensorColor.vala
	Color/NetworkColor.vala
	Json/JsonableTreeMap.vala
	Json/JsonableTreeMapArrayList.vala
	Json/JsonableTreeMultiMap.vala
	Json/JsonableArrayList.vala
	Json/JsonableNode.vala
	Json/JsonableString.vala
	Json/Jsonable.vala
	Json/JsonHelper.vala
	Json/JsonModifierSink.vala
	Json/JsonWrapper/Node.vala
	Json/JsonWrapper/Entry.vala
	Json/JsonWrapper/Iterator.vala
	Json/JsonWrapper/ArrayIterator.vala
	Json/JsonWrapper/ObjectIterator.vala
	Driver/LedDriver.vala
	Driver/Ws2812bDriver.vala
	Driver/Buzzer.vala
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
	Renderer/ClockConfiguration.vala
	Renderer/MatrixRenderer.vala
	Renderer/DotsRenderer.vala
	Renderer/BacklightRenderer.vala
	Renderer/TimeRenderer.vala
	Renderer/WatchHandRenderer.vala
	Renderer/BigTimeRenderer.vala
	Renderer/BigDigitRenderer.vala
	Renderer/BootSequenceRenderer.vala
	Renderer/ColorRenderer.vala
	Renderer/GammaTestRenderer.vala
	Renderer/StringRenderer.vala
	Renderer/ScalaRenderer.vala
	Renderer/ImageRenderer.vala
	Renderer/OWMWeatherRenderer.vala
	Renderer/Tpm2NetRenderer.vala
	Renderer/LuaRenderer.vala
	Renderer/CairoRenderer.vala
	Renderer/TextRenderer.vala
	Font/Font.vala
	Font/MicrosoftSansSerifFont.vala
	Font/HugeMicrosoftSansSerifFont.vala
	Font/ConsolasFont.vala
	Sensors/Lradc.vala
	Sensors/HardwareInfo.vala
	Sensors/SensorsObserver.vala
	Sensors/Gpio.vala
	Sensors/FilteredGpio.vala
	Sensors/Lirc.vala
	Sensors/IrRemote.vala
	Sensors/TimeObserver.vala
	Sensors/SystemSensor.vala
	Sensors/CpuLoad.vala
	Sensors/MemoryUsage.vala
	SignalRouter/SignalRouter.vala
	SignalRouter/SignalSource.vala
	SignalRouter/SignalSink.vala
	SignalRouter/SignalDelayerSink.vala
	System/WpsPbcSink.vala
	System/DateTimeModifierSink.vala
	System/MessageOverlay.vala
	System/SystemInfo.vala
	System/InfoSink.vala
	System/MessageSink.vala
	System/LocationProvider.vala
	System/GoogleLocationProvider.vala
	System/StaticLocationProvider.vala
	System/OWMWeatherProvider.vala
	System/OWMWeatherSink.vala
	System/WirelessNetworks.vala
	System/FirmwareUpdate.vala
	System/StringChooser.vala
	System/StringInput.vala
	System/WirelessNetworkInputSink.vala
	System/ImageOverlay.vala
	System/ImageSink.vala
	Statistic.vala
	Version.vala
)


vala_precompile(VALA_C wordclock
	${VALA_SRC}
PACKAGES 
	libsoup-2.4
	gio-unix-2.0
	gio-2.0
	gee-0.8
	json-glib-1.0
	lua
	cairo
	pango
	pangocairo
	posix
	linux
	wpa_client
OPTIONS 
	--thread
	--target-glib 2.50
	# --debug
# GENERATE_HEADER
	# wordclock
# GENERATE_VAPI
	# wordclock
)

add_executable(wordclock
  	${VALA_C}
)

# null coalescing operator does not work as expected in Color class if -ftree-dse is enabled
# _GNU_SOURCE needed for SCHED_IDLE
add_definitions(-w -fno-tree-dse -DG_LOG_DOMAIN=\"WordClock\" -D_GNU_SOURCE=1)

# explicitly add libraries (needed e.g. for Fedora 13+)
target_link_libraries(wordclock -lm)

install(TARGETS 
	wordclock
RUNTIME
DESTINATION
	/usr/sbin
)
