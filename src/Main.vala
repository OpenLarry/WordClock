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
	public static MessageOverlay message;
	public static OWMWeatherProvider weather;
	
	private static ClockRenderer renderer;
	private static Cancellable cancellable;
	private static MainLoop loop;
	
    public static int main(string[] args) {
		if( !Thread.supported() ) {
			stderr.printf("Cannot run without threads.\n");
			return -1;
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
		
		type = typeof(GoogleLocationProvider);
		type = typeof(StaticLocationProvider);
		
		stdout.printf("WordClock %s\n\n", Version.GIT_DESCRIBE);
		
		// display version only
		if(args.length == 2 && args[1] == "-v") {
			return 0;
		}
		
		cancellable = new Cancellable();
		var driver = new Ws2812bDriver( {4,5,6}, 60, cancellable );
		renderer = new ClockRenderer(new MarkusClockWiring(),driver);
		
		// Parameter -s skips boot sequence
		if(args.length <= 1 || args[1] != "-s") {
			BootSequenceRenderer boot = new BootSequenceRenderer();
			ColorRenderer black = new ColorRenderer();
			black.color.set_hsv(0,0,0);
			renderer.set_overwrite( { black, boot }, { black, boot }, { black, boot } );
		}
		
		hwinfo = new HardwareInfo();
		hwinfo.lradcs["brightness"] = Lradc.get_channel(1);
		hwinfo.lradcs["brightness"].set_scale("0.90332031"); 
		hwinfo.lradcs["vddio"] = Lradc.get_channel(6);
		hwinfo.lradcs["battery"] = Lradc.get_channel(7);
		hwinfo.lradcs["temp"] = Lradc.get_channel(8);
		hwinfo.lradcs["vdd5v"] = Lradc.get_channel(15);
		Lradc.start();
		
		hwinfo.gpios["button0"] = new Gpio(92);
		hwinfo.gpios["button1"] = new Gpio(91);
		hwinfo.gpios["button2"] = new Gpio(23);
		hwinfo.gpios["motion"] = new Gpio(7);
		
		
		var sensorsobserver = new SensorsObserver(hwinfo);
		
		loop = new MainLoop();
		
		var remote = new IrRemote( loop.get_context() );
		
		remote.action.connect((value) => {
			Buzzer.beep(50,2500,255);
		});
		
		var timeobserver = new TimeObserver();
		
		var signalrouter = new SignalRouter();
		signalrouter.add_source("button0", hwinfo.gpios["button0"]);
		signalrouter.add_source("button1", hwinfo.gpios["button1"]);
		signalrouter.add_source("button2", hwinfo.gpios["button2"]);
		signalrouter.add_source("motion", hwinfo.gpios["motion"]);
		signalrouter.add_source("remote", remote);
		signalrouter.add_source("sensorsobserver", sensorsobserver);
		signalrouter.add_source("timeobserver", timeobserver);
		
		message = new MessageOverlay( renderer );
		
		weather = new OWMWeatherProvider();
		
		Lua lua = new Lua();
		
		settings = new Settings("/etc/wordclock/settings.json");
		settings.objects["clockrenderer"] = renderer;
		settings.objects["signalrouter"] = signalrouter;
		settings.objects["sensorsobserver"] = sensorsobserver;
		settings.objects["message"] = message;
		settings.objects["timeobserver"] = timeobserver;
		settings.objects["weather"] = weather;
		settings.objects["lua"] = lua;
		settings.objects.set_keys_immutable();
		
		try{
			// Process button interrupts
			while( loop.get_context().pending() ) loop.get_context().iteration( false );
			
			if(hwinfo.gpios["button0"].value) {
				Buzzer.beep(200,2000,255);
				Thread.usleep(200000);
				Buzzer.beep(200,2000,255);
				Thread.usleep(200000);
				Buzzer.beep(200,2000,255);
				
				message.info("Loading defaults...");
				stdout.puts("Loading default settings!\n");
				settings.load("/etc/wordclock/defaults.json");
			}else{
				try {
					settings.load();
				} catch ( Error e ) {
					if( !(e is FileError.NOENT) ) {
						stderr.printf("Error: %s", e.message);

						
						Buzzer.beep(200,2000,255);
						Thread.usleep(200000);
						Buzzer.beep(200,2000,255);
						Thread.usleep(200000);
						Buzzer.beep(200,2000,255);
						
						message.error("Loading settings failed! Resetting to defaults...");
						stderr.puts("Loading settings failed!\n");
					}
					

					stdout.puts("Loading default settings!\n");
					settings.load("/etc/wordclock/defaults.json");
				}
			}
			
			stdout.puts("Settings loaded!\n");
		} catch( Error e ) {
			stderr.printf("Error: %s\n", e.message);
			return 1;
		}
		
		
		stdout.puts("Run Lua script...\n");
		
		LuaSignals.init(lua, signalrouter);
		LuaSettings.init(lua, settings);
		LuaHwinfo.init(lua, hwinfo);
		LuaMessage.init(lua, message);
		LuaSink.init(lua);
		LuaBuzzer.init(lua);
		LuaRenderer.init(lua);
		try {
			lua.run();
		}catch(LuaError e) {
			stderr.printf("Lua error: %s\n", e.message);
		}
		
		try{
			stdout.puts("Starting REST server...\n");
			new RestServer();
			stdout.puts("Running!\n");
		} catch( Error e ) {
			stdout.printf("Error %s\n", e.message);
			return 2;
		}
		
		var signalsource = new Unix.SignalSource( Posix.SIGTERM );
		signalsource.set_callback(Main.shutdown);
		signalsource.attach( loop.get_context() );
		
		signalsource = new Unix.SignalSource( Posix.SIGHUP );
		signalsource.set_callback(Main.shutdown);
		signalsource.attach( loop.get_context() );
		
		signalsource = new Unix.SignalSource( Posix.SIGINT );
		signalsource.set_callback(Main.shutdown);
		signalsource.attach( loop.get_context() );
		
		var thread = new Thread<int>("Ws2812bDriver", () => {
			// set real-time scheduling policy
			Posix.Sched.Param param = { 1 };
			int ret = Posix.Sched.setscheduler(0, Posix.Sched.Algorithm.FIFO, ref param);
			GLib.assert(ret==0); GLib.debug("Set scheduler");
			
			return driver.start(renderer);
		});
		
		Buzzer.beep(100,2000,10);
		Buzzer.beep(400,4000,10);
		
		loop.run();
		
		
		stdout.puts("Terminating. Waiting for threads...\n");
		
		Buzzer.beep(100,4000,10);
		Buzzer.beep(100,2000,10);
		
		Lradc.stop();
		try{
			settings.check_save();
		}catch( Error e ) {
			stderr.printf("Error: %s\n", e.message);
		}
		
		thread.join();
		
		stdout.puts("Bye!\n");
		
		return 0;
    }
	
	public static bool shutdown() {
		cancellable.cancel();
		loop.quit();
		
		return Source.REMOVE;
	}
}

