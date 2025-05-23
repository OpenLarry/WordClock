using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Main : GLib.Object {
	public static TimeZone timezone;
	
	public static HardwareInfo hwinfo;
	public static Settings settings;
	public static WirelessNetworks wireless_networks;
	
	private static ClockRenderer renderer;
	private static Cancellable cancellable;
	private static MainLoop loop;
	
	private static bool version = false;
	private static bool debug_mode = false;
	private static bool silent = false;
	private static int port = 8080;
	
	private const OptionEntry[] options = {
		{ "version", 'v', 0, OptionArg.NONE, ref version, "Display version number", null },
		{ "debug", 'd', 0, OptionArg.NONE, ref debug_mode, "Enable debug mode (no syslog, no intro, no sound)", null },
		{ "silent", 's', 0, OptionArg.NONE, ref silent, "Disable sound output", null },
		{ "port", 'p', 0, OptionArg.INT, ref port, "HTTP port number", "PORT" },
		{ null }
	};
	
    public static int main(string[] args) {
		try {
			OptionContext opt_context = new OptionContext();
			opt_context.set_help_enabled(true);
			opt_context.add_main_entries(options, null);
			opt_context.parse(ref args);
		} catch (OptionError e) {
			stdout.printf ("error: %s\n", e.message);
			stdout.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
			return 1;
		}
		
		Posix.openlog("wordclock", Posix.LOG_PID, Posix.LOG_LOCAL1);
		Log.set_default_handler((log_domain, log_levels, message) => {
			if(log_domain == "WordClock" || ((log_levels & LogLevelFlags.LEVEL_MASK) & (LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING | LogLevelFlags.LEVEL_MESSAGE)) > 0) {
				int level;
				switch(log_levels & LogLevelFlags.LEVEL_MASK) {
					case LogLevelFlags.LEVEL_ERROR: level = Posix.LOG_ERR; break;
					case LogLevelFlags.LEVEL_CRITICAL: level = Posix.LOG_ERR; break;
					case LogLevelFlags.LEVEL_WARNING: level = Posix.LOG_WARNING; break;
					case LogLevelFlags.LEVEL_MESSAGE: level = Posix.LOG_NOTICE; break;
					case LogLevelFlags.LEVEL_INFO: level = Posix.LOG_INFO; break;
					case LogLevelFlags.LEVEL_DEBUG: default: level = Posix.LOG_DEBUG; break;
				}
				
				if(!debug_mode) Posix.syslog(level, "%s\n", message);
			}
			
			Log.default_handler(log_domain, log_levels, message);
		});
		
		Process.signal(ProcessSignal.ILL, () => { error("Illegal instruction"); });
		Process.signal(ProcessSignal.FPE, () => { error("Floating-point exception"); });
		Process.signal(ProcessSignal.SEGV, () => { error("Segmentation fault"); });
		
		if( !Thread.supported() ) {
			error("Cannot run without threads");
		}
		
		Intl.setlocale( LocaleCategory.ALL, "" );
		Intl.setlocale( LocaleCategory.NUMERIC, "C" );
		
		// cache timezone
		timezone = new TimeZone.local();
		
		// Register Types: http://valadoc.org/#!api=gobject-2.0/GLib.Type.from_name
		Type? type = typeof(Color);
		type = typeof(HueRotateColor);
		type = typeof(BrightnessSensorColor);
		type = typeof(NetworkColor);
		type = typeof(ModifyColor);
		
		type = typeof(Buzzer);
		
		type = typeof(WestGermanFrontPanel);
		type = typeof(EastGermanFrontPanel);
		type = typeof(RhineRuhrGermanFrontPanel);
		
		type = typeof(ClockRenderer);
		type = typeof(ClockConfiguration);
		type = typeof(TimeRenderer);
		type = typeof(BootSequenceRenderer);
		type = typeof(ColorRenderer);
		type = typeof(GammaTestRenderer);
		type = typeof(WatchHandRenderer);
		type = typeof(ScalaRenderer);
		type = typeof(ImageRenderer);
		type = typeof(OWMWeatherRenderer);
		type = typeof(Tpm2NetRenderer);
		type = typeof(LuaRenderer);
		type = typeof(TextRenderer);
		
		type = typeof(JsonableTreeMap);
		type = typeof(JsonableArrayList);
		type = typeof(JsonableNode);
		type = typeof(JsonModifierSink);
		
		type = typeof(WpsPbcSink);
		type = typeof(DateTimeModifierSink);
		type = typeof(InfoSink);
		type = typeof(MessageSink);
		type = typeof(SignalDelayerSink);
		type = typeof(OWMWeatherSink);
		type = typeof(WirelessNetworkInputSink);
		type = typeof(LuaSink);
		type = typeof(ImageSink);
		
		type = typeof(GoogleLocationProvider);
		type = typeof(StaticLocationProvider);
		
		print("WordClock %s\n\n", Version.GIT_DESCRIBE);
		
		// display version only
		if(version) {
			return 0;
		}
		
		try {
			debug("Starting WordClock %s", Version.GIT_DESCRIBE);
			
			debug("Load port config");
			JsonWrapper.Node port_config = new JsonWrapper.Node.from_json_file("/etc/wordclock/ports.json");
			
			debug("Init Ws2812bDriver");
			cancellable = new Cancellable();
			uint8[] ports = port_config["ws2812b"]["ports"].get_uint8_array();
			uint8 leds = (uint8) port_config["ws2812b"]["leds"].get_typed_value(typeof(uint8));
			var driver = new Ws2812bDriver( ports, leds, cancellable );
			renderer = new ClockRenderer(new MarkusClockWiring(),driver);
			
			debug("Init LRADCs");
			hwinfo = new HardwareInfo();
			
			foreach( JsonWrapper.Entry entry in port_config["lradc"] ) {
				hwinfo.lradcs[entry.get_member_name()] = Lradc.get_channel((uint8) entry.value.get_typed_value(typeof(uint8)));
			}
			foreach( JsonWrapper.Entry entry in port_config["lradc-scale"] ) {
				hwinfo.lradcs[entry.get_member_name()].set_scale(entry.value.to_string());
			}
			Lradc.start();
			
			// TODO: remove
			debug("Init GPIOs");
			foreach( JsonWrapper.Entry entry in port_config["gpio"] ) {
				hwinfo.gpios[entry.get_member_name()] = new Gpio((uint8) entry.value.get_typed_value(typeof(uint8)));
			}

			debug("Init Buttons");
			var buttons = new DevInput(port_config["button"]["device"].to_string());
			buttons.add_code( "left", Linux.Input.BTN_LEFT );
			buttons.add_code( "middle", Linux.Input.BTN_MIDDLE );
			buttons.add_code( "right", Linux.Input.BTN_RIGHT );

			debug("Init Motion");
			var motion = new DevInput(port_config["motion"]["device"].to_string());
			motion.add_code( "detection", Linux.Input.SW_FRONT_PROXIMITY, Linux.Input.EV_SW );
			
			debug("Init ButtonHandler");
			var buttonhandler = new ButtonHandler();
			buttonhandler.add_input(buttons);
			
			debug("Init CPU and memory monitors");
			hwinfo.system["cpuload"] = new CpuLoad();
			hwinfo.system["memoryusage"] = new MemoryUsage();
			hwinfo.system["leddriver"] = driver;
			
			debug("Init SensorsObserver");
			var sensorsobserver = new SensorsObserver(hwinfo);
			
			if(!silent) {
				debug("Init Buzzer");
				Buzzer.init((uint8) port_config["buzzer"]["pwm-port"].get_typed_value(typeof(uint8)));
			}
			
			debug("Init MainLoop");
			loop = new MainLoop();
			
			debug("Init RemoteControl");
			var remote = new RemoteControl(port_config["remotecontrol"]["event-device"].to_string(), port_config["remotecontrol"]["ir-device"].to_string(), port_config["remotecontrol"]["protocols"].get_string_array());
			foreach( JsonWrapper.Entry entry in port_config["remotecontrol"]["keys"] ) {
				remote.add_scancode(entry.get_member_name(), entry.value.get_uint8_array());
			}
			
			debug("Init TimeObserver");
			var timeobserver = new TimeObserver();
			
			debug("Init SignalRouter");
			var signalrouter = new SignalRouter();
			signalrouter.add_source("remote", remote);
			signalrouter.add_source("button", buttons);
			signalrouter.add_source("motion", motion);
			signalrouter.add_source("sensorsobserver", sensorsobserver);
			signalrouter.add_source("timeobserver", timeobserver);
			signalrouter.add_source("buttonhandler", buttonhandler);
			
			debug("Init MessageOverlay");
			MessageOverlay message = new MessageOverlay( renderer );
			
			debug("Init ImageOverlay");
			ImageOverlay image = new ImageOverlay( renderer );
			
			debug("Init OWMWeatherProvider");
			OWMWeatherProvider weather = new OWMWeatherProvider();
			
			debug("Init Lua");
			Lua lua = new Lua();
			
			debug("Init WirelessNetworks");
			WirelessNetworks wirelessnetworks = new WirelessNetworks();

			debug("Init BootSequenceRenderer");
			BootSequenceRenderer bootsequence = new BootSequenceRenderer();
			
			debug("Init Settings");
			settings = new Settings();
			settings.set("clockrenderer", renderer);
			settings.set("signalrouter", signalrouter);
			settings.set("sensorsobserver", sensorsobserver);
			settings.set("message", message);
			settings.set("image", image);
			settings.set("timeobserver", timeobserver);
			settings.set("weather", weather);
			settings.set("lua", lua);
			settings.set("wirelessnetworks", wirelessnetworks);
			settings.set("bootsequence", bootsequence);
			settings.objects.set_keys_immutable();
			
			debug("Init TestSequenceRenderer");
			TestSequenceRenderer tsr = new TestSequenceRenderer();
			tsr.register();
			
			debug("Init Lua modules");
			LuaSignals.init(lua, signalrouter);
			LuaSettings.init(lua, settings);
			LuaHwinfo.init(lua, hwinfo);
			LuaMessage.init(lua, message);
			LuaImage.init(lua, image);
			LuaSink.init(lua);
			LuaBuzzer.init(lua);
			LuaRenderer.init(lua);
			
			// Process button interrupts
			while( loop.get_context().pending() ) loop.get_context().iteration( false );
			
			// reset requested (left button)
			if(hwinfo.gpios["button0"].value) {
				Buzzer.beep(200,2000,255);
				Buzzer.pause(200);
				Buzzer.beep(200,2000,255);
				Buzzer.pause(200);
				Buzzer.beep(200,2000,255);
				
				message.info("Loading default settings...");
				settings.load("defaults");
			}else{
				try {
					settings.load();
				
					try {
						lua.run();
					}catch(LuaError e) {
						warning("Lua error: %s", e.message);
					}
				} catch ( Error e ) {
					critical("Loading settings failed: %s", e.message);
					message.error("Loading settings failed! Resetting to defaults...");
					
					if(!debug_mode) {
						Buzzer.beep(200,2000,255);
						Buzzer.pause(200);
						Buzzer.beep(200,2000,255);
						Buzzer.pause(200);
						Buzzer.beep(200,2000,255);
					}
					
					settings.load("defaults");
				}
			}
			
			new RestServer((uint16) port);
			
			debug("Register Posix signal callbacks");
			var signalsource = new Unix.SignalSource( Posix.Signal.TERM );
			signalsource.set_callback(Main.shutdown);
			signalsource.attach( loop.get_context() );
			
			signalsource = new Unix.SignalSource( Posix.Signal.HUP );
			signalsource.set_callback(Main.shutdown);
			signalsource.attach( loop.get_context() );
			
			signalsource = new Unix.SignalSource( Posix.Signal.INT );
			signalsource.set_callback(Main.shutdown);
			signalsource.attach( loop.get_context() );
			
			// Debug parameter skips boot sequence
			if(!debug_mode) {
				debug("Setup boot sequence");
				ColorRenderer black = new ColorRenderer();
				black.color.set_hsv(0,0,0);
				renderer.overwrite.begin( { black, bootsequence }, { black, bootsequence }, { black, bootsequence }, null, () => {
					debug("Boot sequence finished");
				});
			}
			
			debug("Run renderer thread");
			var thread = new Thread<int>("Ws2812bDriver", () => {
				// set real-time scheduling policy
				Posix.Sched.Param param = { 1 };
				int ret = Posix.Sched.setscheduler(0, Posix.Sched.Algorithm.FIFO, ref param);
				assert(ret==0);
				
				return driver.start(renderer);
			});
			
			if(!debug_mode) {
				debug("Make beep sound");
				Buzzer.beep(100,2000,10);
				Buzzer.beep(400,4000,10);
			}
			
			debug("Run main loop");
			loop.run();
			debug("Terminating");
			
			if(!debug_mode) {
				debug("Make beep sound");
				Buzzer.beep(100,4000,10);
				Buzzer.beep(100,2000,10);
			}
			
			debug("Stop LRADCs");
			Lradc.stop();
			
			debug("Save pending changes");
			try{
				settings.check_save();
			}catch( Error e ) {
				critical(e.message);
			}
			
			debug("Wait for threads");
			thread.join();
			Buzzer.deinit();
			
			debug("Program end");
			Posix.closelog();
			
			print("Bye!\n");		
		} catch( Error e ) {
			error(e.message);
		}
		
		return 0;
    }
	
	public static bool shutdown() {
		debug("Shutdown triggered");
		cancellable.cancel();
		loop.quit();
		
		return Source.REMOVE;
	}
    
    public static bool in_debug_mode() {
        return debug_mode;
    }
}

namespace WordClock {
	public async void async_sleep( uint time, Cancellable? cancel = null ) {
		uint timeout_id = 0;
		ulong cancel_id = 0;
		
		timeout_id = GLib.Timeout.add(time, () => {
			async_sleep.callback();
			timeout_id = 0;
			return Source.REMOVE;
		});
		if(cancel != null) {
			cancel_id = cancel.connect(() => {
				async_sleep.callback();
			});
		}
		yield;
		if(cancel != null && !cancel.is_cancelled()) cancel.disconnect(cancel_id);
		if(timeout_id > 0) Source.remove(timeout_id);
	}
}
