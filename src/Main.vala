using WordClock;
using SDLImage;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Main : GLib.Object {
	public static TimeZone timezone;
	
	public static HardwareInfo hwinfo;
	public static Settings settings;
	
	private static ClockRenderer renderer;
	private static Cancellable cancellable;
	private static MainLoop loop;
	
    public static int main(string[] args) {
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
				
				Posix.syslog(level, "%s\n", message);
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
		
		type = typeof(Buzzer);
		
		type = typeof(WestGermanFrontPanel);
		type = typeof(EastGermanFrontPanel);
		type = typeof(RhineRuhrGermanFrontPanel);
		type = typeof(MicrosoftSansSerifFont);
		type = typeof(HugeMicrosoftSansSerifFont);
		type = typeof(ConsolasFont);
		
		type = typeof(ClockRenderer);
		type = typeof(ClockConfiguration);
		type = typeof(TimeRenderer);
		type = typeof(BigTimeRenderer);
		type = typeof(BigDigitRenderer);
		type = typeof(BootSequenceRenderer);
		type = typeof(ColorRenderer);
		type = typeof(GammaTestRenderer);
		type = typeof(StringRenderer);
		type = typeof(WatchHandRenderer);
		type = typeof(ScalaRenderer);
		type = typeof(ImageRenderer);
		type = typeof(OWMWeatherRenderer);
		type = typeof(Tpm2NetRenderer);
		type = typeof(LuaRenderer);
		
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
		
		type = typeof(GoogleLocationProvider);
		type = typeof(StaticLocationProvider);
		
		print("WordClock %s\n\n", Version.GIT_DESCRIBE);
		
		// display version only
		if(args.length == 2 && args[1] == "-v") {
			return 0;
		}
		
		debug("Starting WordClock %s", Version.GIT_DESCRIBE);
		
		debug("Init Ws2812bDriver");
		cancellable = new Cancellable();
		var driver = new Ws2812bDriver( {4,5,6}, 60, cancellable );
		renderer = new ClockRenderer(new MarkusClockWiring(),driver);
		
		// Parameter -s skips boot sequence
		if(args.length <= 1 || args[1] != "-s") {
			BootSequenceRenderer boot = new BootSequenceRenderer();
			ColorRenderer black = new ColorRenderer();
			black.color.set_hsv(0,0,0);
			renderer.overwrite.begin( { black, boot }, { black, boot }, { black, boot }, null, () => {
				debug("Boot sequence finished");
			});
		}
		
		debug("Init LRADCs");
		hwinfo = new HardwareInfo();
		hwinfo.lradcs["brightness"] = Lradc.get_channel(1);
		hwinfo.lradcs["brightness"].set_scale("0.90332031"); 
		hwinfo.lradcs["vddio"] = Lradc.get_channel(6);
		hwinfo.lradcs["battery"] = Lradc.get_channel(7);
		hwinfo.lradcs["temp"] = Lradc.get_channel(8);
		hwinfo.lradcs["vdd5v"] = Lradc.get_channel(15);
		Lradc.start();
		
		debug("Init GPIOs");
		hwinfo.gpios["button0"] = new Gpio(92);
		hwinfo.gpios["button1"] = new Gpio(91);
		hwinfo.gpios["button2"] = new Gpio(23);
		hwinfo.gpios["motion"] = new Gpio(7);
		var filteredmotion = new FilteredGpio(hwinfo.gpios["motion"]);
		
		debug("Init CPU and memory monitors");
		hwinfo.system["cpuload"] = new CpuLoad();
		hwinfo.system["memoryusage"] = new MemoryUsage();
		hwinfo.system["leddriver"] = driver;
		
		debug("Init SensorsObserver");
		var sensorsobserver = new SensorsObserver(hwinfo);
		
		debug("Init MainLoop");
		loop = new MainLoop();
		
		debug("Init IR remote");
		var remote = new IrRemote( loop.get_context() );
		
		remote.action.connect((value) => {
			Buzzer.beep(50,2500,255);
		});
		
		debug("Init TimeObserver");
		var timeobserver = new TimeObserver();
		
		debug("Init SignalRouter");
		var signalrouter = new SignalRouter();
		signalrouter.add_source("button0", hwinfo.gpios["button0"]);
		signalrouter.add_source("button1", hwinfo.gpios["button1"]);
		signalrouter.add_source("button2", hwinfo.gpios["button2"]);
		signalrouter.add_source("filteredmotion", filteredmotion);
		signalrouter.add_source("motion", hwinfo.gpios["motion"]);
		signalrouter.add_source("remote", remote);
		signalrouter.add_source("sensorsobserver", sensorsobserver);
		signalrouter.add_source("timeobserver", timeobserver);
		
		debug("Init MessageOverlay");
		MessageOverlay message = new MessageOverlay( renderer );
		
		debug("Init OWMWeatherProvider");
		OWMWeatherProvider weather = new OWMWeatherProvider();
		
		debug("Init Lua");
		Lua lua = new Lua();
		
		debug("Init Settings");
		settings = new Settings("/etc/wordclock/settings.json");
		settings.objects["clockrenderer"] = renderer;
		settings.objects["signalrouter"] = signalrouter;
		settings.objects["sensorsobserver"] = sensorsobserver;
		settings.objects["message"] = message;
		settings.objects["timeobserver"] = timeobserver;
		settings.objects["weather"] = weather;
		settings.objects["lua"] = lua;
		settings.objects["filteredmotion"] = filteredmotion;
		settings.objects.set_keys_immutable();
		
		debug("Init Lua modules");
		LuaSignals.init(lua, signalrouter);
		LuaSettings.init(lua, settings);
		LuaHwinfo.init(lua, hwinfo);
		LuaMessage.init(lua, message);
		LuaSink.init(lua);
		LuaBuzzer.init(lua);
		LuaRenderer.init(lua);
		
		try{
			// Process button interrupts
			while( loop.get_context().pending() ) loop.get_context().iteration( false );
			
			if(hwinfo.gpios["button0"].value) {
				Buzzer.beep(200,2000,255);
				Thread.usleep(200000);
				Buzzer.beep(200,2000,255);
				Thread.usleep(200000);
				Buzzer.beep(200,2000,255);
				
				message.info("Loading default settings...");
				debug("Loading default settings");
				settings.load("/etc/wordclock/defaults.json");
			}else{
				try {
					settings.load();
				
					try {
						lua.run();
					}catch(LuaError e) {
						warning("Lua error: %s", e.message);
					}
				} catch ( Error e ) {
					if( !(e is FileError.NOENT) ) {
						warning("Loading settings failed: %s", e.message);
						message.error("Loading settings failed! Resetting to defaults...");
						
						Buzzer.beep(200,2000,255);
						Thread.usleep(200000);
						Buzzer.beep(200,2000,255);
						Thread.usleep(200000);
						Buzzer.beep(200,2000,255);
					}
					

					debug("Loading default settings");
					settings.load("/etc/wordclock/defaults.json");
				}
			}
			
		} catch( Error e ) {
			error(e.message);
		}
		
		
		try{
			new RestServer();
		} catch( Error e ) {
			error(e.message);
		}
		
		debug("Register Posix signal callbacks");
		var signalsource = new Unix.SignalSource( Posix.SIGTERM );
		signalsource.set_callback(Main.shutdown);
		signalsource.attach( loop.get_context() );
		
		signalsource = new Unix.SignalSource( Posix.SIGHUP );
		signalsource.set_callback(Main.shutdown);
		signalsource.attach( loop.get_context() );
		
		signalsource = new Unix.SignalSource( Posix.SIGINT );
		signalsource.set_callback(Main.shutdown);
		signalsource.attach( loop.get_context() );
		
		debug("Run renderer thread");
		var thread = new Thread<int>("Ws2812bDriver", () => {
			// set real-time scheduling policy
			Posix.Sched.Param param = { 1 };
			int ret = Posix.Sched.setscheduler(0, Posix.Sched.Algorithm.FIFO, ref param);
			assert(ret==0);
			
			return driver.start(renderer);
		});
		
		// Parameter -s skips beep sound
		if(args.length <= 1 || args[1] != "-s") {
			debug("Make beep sound");
			Buzzer.beep(100,2000,10);
			Buzzer.beep(400,4000,10);
		}
		
		debug("Run main loop");
		loop.run();
		debug("Terminating");
		
		// Parameter -s skips beep sound
		if(args.length <= 1 || args[1] != "-s") {
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
		
		debug("Wait for renderer thread");
		thread.join();
		
		debug("Program end");
		Posix.closelog();
		
		print("Bye!\n");
		
		return 0;
    }
	
	public static bool shutdown() {
		debug("Shutdown triggered");
		cancellable.cancel();
		loop.quit();
		
		return Source.REMOVE;
	}
}

