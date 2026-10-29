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
			
			debug("Init MainLoop");
			loop = new MainLoop();
			
			// Process button interrupts
			while( loop.get_context().pending() ) loop.get_context().iteration( false );
			
			
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
			
			debug("Setup boot sequence");
			ColorRenderer black = new ColorRenderer();
			black.color.set_hsv(0,0,50);
			renderer.overwrite.begin( { black }, { black }, { black }, null, () => {
				debug("Boot sequence finished");
			});
			
			debug("Run renderer thread");
			var thread = new Thread<int>("Ws2812bDriver", () => {
				// set real-time scheduling policy
				Posix.Sched.Param param = { 1 };
				int ret = Posix.Sched.setscheduler(0, Posix.Sched.Algorithm.FIFO, ref param);
				assert(ret==0);
				
				return driver.start(renderer);
			});
			
			
			debug("Run main loop");
			loop.run();
			debug("Terminating");
			
			
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
