using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Main : GLib.Object {
	public static Gpio button0;
	public static Gpio button1;
	public static Gpio button2;
	public static Gpio motion;
	public static Sensors sensors;
	
	public static int wps_lock;
	
	public static Settings settings;
	
	private static ClockRenderer renderer;
	private static Cancellable cancellable;
	private static MainLoop loop;
	
    public static int main(string[] args) {
		if( !Thread.supported() ) {
			stderr.printf("Cannot run without threads.\n");
			return -1;
		}
		
		// Register Types: http://valadoc.org/#!api=gobject-2.0/GLib.Type.from_name
		Type? type = typeof(Color);
		type = typeof(HueRotateColor);
		type = typeof(BrightnessSensorColor);
		
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
		type = typeof(TestSequenceRenderer);
		type = typeof(ColorRenderer);
		type = typeof(GammaTestRenderer);
		type = typeof(StringRenderer);
		type = typeof(SecondsRenderer);
		
		type = typeof(JsonableTreeMap);
		type = typeof(JsonableArrayList);
		type = typeof(JsonableNode);
		type = typeof(JsonModifierSink);
		
		stdout.puts("Wordclock 1.0\n\n");
		
		cancellable = new Cancellable();
		var driver = new Ws2812bDriver( {4,5,6}, 60, cancellable );
		renderer = new ClockRenderer(new MarkusClockWiring(),driver);
		
		sensors = new Sensors();
		
		button0 = new Gpio(92);
		button1 = new Gpio(91);
		button2 = new Gpio(23);
		motion = new Gpio(7);
		
		var sensorsobserver = new SensorsObserver(sensors);
		
		motion.action.connect((value) => {
			Buzzer.beep(100,(value=="1")?2500:1500,255);
		});
		
		loop = new MainLoop();
		
		var remote = new IrRemote( loop.get_context() );
		
		remote.action.connect((value) => {
			Buzzer.beep(50,2500,255);
		});
		
		var signalrouter = new SignalRouter();
		signalrouter.add_source("button0", button0);
		signalrouter.add_source("button1", button1);
		signalrouter.add_source("button2", button2);
		signalrouter.add_source("motion", motion);
		signalrouter.add_source("remote", remote);
		signalrouter.add_source("sensorsobserver", sensorsobserver);
		
		settings = new Settings("settings.json");
		settings.objects["clockrenderer"] = renderer;
		settings.objects["signalrouter"] = signalrouter;
		settings.objects["sensorsobserver"] = sensorsobserver;
		
		try{
			settings.load();
			stdout.puts("Settings loaded!\n");
		} catch( Error e ) {
			stderr.printf("Error: %s\n", e.message);
		}
		
		
		
		try{
			stdout.puts("Starting REST server...\n");
			new RestServer();
			stdout.puts("Running!\n");
		} catch( Error e ) {
			stdout.printf("Error %s\n", e.message);
		}
		
		
		
		GLib.Timeout.add(500, () => {
			sensors.read();
			return true;
		});
		
		var signalsource = new Unix.SignalSource( Posix.SIGTERM );
		signalsource.set_callback(Main.shutdown);
		signalsource.attach( loop.get_context() );
		
		signalsource = new Unix.SignalSource( Posix.SIGHUP );
		signalsource.set_callback(Main.shutdown);
		signalsource.attach( loop.get_context() );
		
		signalsource = new Unix.SignalSource( Posix.SIGINT );
		signalsource.set_callback(Main.shutdown);
		signalsource.attach( loop.get_context() );
		
		
		button0 = new Gpio(92);
		button1 = new Gpio(91);
		button2 = new Gpio(23);
		motion = new Gpio(7);
		
		// button0.action.connect((value) => {
			// if(value) {
				// try{
					// Process.spawn_command_line_sync("date +%%T -s \"%s\"".printf( new DateTime.now_local().add_hours(1).format("%T") ));
				// }catch(Error e) {
					// stderr.printf("%s\n",e.message);
				// }
			// }
		// });
		// button1.action.connect((value) => {
			// if(value) {
				// try{
					// Process.spawn_command_line_sync("date +%%T -s \"%s\"".printf( new DateTime.now_local().add_minutes(1).format("%T") ));
				// }catch(Error e) {
					// stderr.printf("%s\n",e.message);
				// }
			// }
		// });
		
		button2.action.connect((value) => {
			if(value=="1") {
				try{
					new Thread<int>.try("WPS PBC", () => {
						lock(wps_lock) {
							try{
								Process.spawn_command_line_sync("wpa_cli wps_pbc");
								
								string output="";
								do {
									Buzzer.beep(100,2000,25);
									Process.spawn_command_line_sync("wpa_cli status", out output);
									stdout.printf("WPS: %s\n", output);
									Thread.usleep(1000000);
								} while(output.contains("wpa_state=DISCONNECTED") || output.contains("wpa_state=SCANNING") || output.contains("wpa_state=ASSOCIATING") || output.contains("wpa_state=ASSOCIATED"));
								
								if(output.contains("wpa_state=COMPLETED")) {
									Buzzer.beep(100,3000,25);
									Buzzer.beep(400,4000,25);
								}else{
									Buzzer.beep(200,1000,25);
									Thread.usleep(200000);
									Buzzer.beep(200,1000,25);
								}
							}catch(Error e) {
								stderr.printf("%s\n",e.message);
							}
						}
						return 0;
					});
				}catch(Error e) {
					stderr.printf("%s\n",e.message);
				}
			}
		});
		
		
		
		try {
			string active = renderer.active;
			renderer.active = "on";
			Thread<int> thread = new Thread<int>.try("Ws2812bDriver", () => { return driver.start(renderer); });
			
			Buzzer.beep(100,2000,10);
			Buzzer.beep(400,4000,10);
			
			thread.join();
			
			renderer.active = active;
			thread = new Thread<int>.try("Ws2812bDriver", () => { return driver.start(renderer); });
			
			loop.run();
			
			
			stdout.puts("Terminating. Waiting for threads...\n");
			
			Buzzer.beep(100,4000,10);
			Buzzer.beep(100,2000,10);
			
			thread.join();
			
		} catch ( Error e ) {
			stderr.printf("Thread error: %s", e.message);
			return 1;
		}
		
		stdout.puts("Bye!\n");
		
		return 0;
    }
	
	public static bool shutdown() {
		renderer.active = "off";
		Thread.usleep(1000000);
		cancellable.cancel();
		loop.quit();
		
		return Source.REMOVE;
	}
}

