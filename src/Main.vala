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
	
	public static JsonSettings settings;
	
	private static ClockRenderer renderer;
	private static Cancellable cancellable;
	private static MainLoop loop;
	
    public static int main(string[] args) {
		if( !Thread.supported() ) {
			stderr.printf("Cannot run without threads.\n");
			return -1;
		}
		
		// Register FrontPanels: http://valadoc.org/#!api=gobject-2.0/GLib.Type.from_name
		Type? type = typeof(WestGermanFrontPanel);
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
		
		stdout.puts("Wordclock 1.0\n\n");
		
		cancellable = new Cancellable();
		var driver = new Ws2812bDriver( {4,5,6}, 60, cancellable );
		renderer = new ClockRenderer(new MarkusClockWiring(),driver);
		
		sensors = new Sensors();
		
		settings = new JsonSettings("settings/settings.json");
		settings.objects["clockrenderer"] = renderer;
		
		renderer.renderers["Time"] = new TimeRenderer();
		renderer.renderers["BigTime"] = new BigTimeRenderer();
		renderer.renderers["Test"] = new TestSequenceRenderer();
		renderer.renderers["Color"] = new ColorRenderer();
		renderer.renderers["GammaTest"] = new GammaTestRenderer();
		renderer.renderers["Seconds"] = new SecondsRenderer();
		
		renderer.configurations["default"] = new ClockConfiguration("Time","Time","Seconds");
		renderer.active = "default";
		
		settings.load_data();
		stdout.puts("Loaded!\n");
		
		
		loop = new MainLoop();
		
		try{
			stdout.puts("Starting REST server...\n");
			new RestServer();
			stdout.puts("Running!\n");
		} catch( Error e ) {
			stdout.printf("Error %s\n", e.message);
		}
		
		/*
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
		
		button0 = new Gpio(4);
		button1 = new Gpio(5);
		button2 = new Gpio(6);
		motion = new Gpio(7);
		
		button0.update.connect((value) => {
			if(value) {
				try{
					Process.spawn_command_line_sync("date +%%T -s \"%s\"".printf( new DateTime.now_local().add_hours(1).format("%T") ));
				}catch(Error e) {
					stderr.printf("%s\n",e.message);
				}
			}
			Buzzer.beep(100,(value)?2500:1500,255);
		});
		button1.update.connect((value) => {
			if(value) {
				try{
					Process.spawn_command_line_sync("date +%%T -s \"%s\"".printf( new DateTime.now_local().add_minutes(1).format("%T") ));
				}catch(Error e) {
					stderr.printf("%s\n",e.message);
				}
			}
			Buzzer.beep(100,(value)?2500:1500,255);
		});
		button2.update.connect((value) => {
			if(value) {
				try{
					Process.spawn_command_line_sync("date +%%T -s \"%s\"".printf( new DateTime.now_local().add_seconds(1).format("%T") ));
				}catch(Error e) {
					stderr.printf("%s\n",e.message);
				}
			}
			Buzzer.beep(100,(value)?2500:1500,255);
		});
		motion.update.connect((value) => {
			Buzzer.beep(100,(value)?2500:1500,255);
		});
		
		bool background = seconds.background_color.get_hsv()[2] > 0;
		uint8 brightness = (uint8) seconds.seconds_color.get_hsv()[2];
		uint8 toggle = 0;
		
		try{
			var context = new Lirc.Context("wordclock-remote");
			var listener = new Lirc.Listener(context, loop.get_context());
		
			listener.button.connect((device_conf, interpreted_key_code, repetition_number) => {
				if(repetition_number == 0) Buzzer.beep(10);
				
				if(interpreted_key_code == "STROBE" && repetition_number == 0) {
					toggle += 1;
					switch(toggle%3) {
						case 0:
							renderer.matrix = "Time";
							renderer.dots = "Time";
							renderer.backlight = "Seconds";
						break;
						case 1:
							renderer.matrix = "BigTime";
							renderer.dots = "Black";
							renderer.backlight = "Seconds";
						break;
						case 2:
							renderer.matrix = "String";
							renderer.dots = "Black";
							renderer.backlight = "Seconds";
						break;
					}
				}
				if(interpreted_key_code == "STROBE" && repetition_number == 20) {
					renderer.matrix = "GammaTest";
					renderer.dots = "GammaTest";
					renderer.backlight = "GammaTest";
				}
				
				if(interpreted_key_code == "FLASH" && repetition_number == 0) {
					background = !background;
					seconds.background_color = new Color.from_hsv(0,0,(background) ? brightness : 0);
				}
				
				if(interpreted_key_code == "UP") {
					if(brightness + repetition_number+1 > 255) {
						brightness = 255;
					}else{
						brightness += repetition_number+1;
					}
					
					seconds.seconds_color.set_hsv(null,null,brightness);
					seconds.background_color.set_hsv(null,null,(background) ? brightness : 0);
					bigtime.hours_color.set_hsv(null,null,brightness);
					bigtime.minutes_color.set_hsv(null,null,brightness);
					time.words_color.set_hsv(null,null,brightness);
					time.dots_color.set_hsv(null,null,brightness);
					str.left_color.set_hsv(null,null,brightness);
					str.right_color.set_hsv(null,null,brightness);
					seconds.notify_property("seconds_color");
					seconds.notify_property("background_color");
					bigtime.notify_property("hours_color");
					bigtime.notify_property("minutes_color");
					time.notify_property("words_color");
					time.notify_property("dots_color");
					str.notify_property("left_color");
					str.notify_property("right_color");
				}
				if(interpreted_key_code == "DOWN") {
					if(brightness - repetition_number-1 < 0) {
						brightness = 0;
					}else{
						brightness -= repetition_number+1;
					}
					
					seconds.seconds_color.set_hsv(null,null,brightness);
					seconds.background_color.set_hsv(null,null,(background) ? brightness : 0);
					bigtime.hours_color.set_hsv(null,null,brightness);
					bigtime.minutes_color.set_hsv(null,null,brightness);
					time.words_color.set_hsv(null,null,brightness);
					time.dots_color.set_hsv(null,null,brightness);
					str.left_color.set_hsv(null,null,brightness);
					str.right_color.set_hsv(null,null,brightness);
					seconds.notify_property("seconds_color");
					seconds.notify_property("background_color");
					bigtime.notify_property("hours_color");
					bigtime.notify_property("minutes_color");
					time.notify_property("words_color");
					time.notify_property("dots_color");
					str.notify_property("left_color");
					str.notify_property("right_color");
				}
				
				uint16 n = 0;
				if(interpreted_key_code == "R") {
					str.left_color.set_hsv(0,255,null);
					str.right_color.set_hsv(0,255,null);
					str.notify_property("left_color");
					str.notify_property("right_color");
				}
				if(interpreted_key_code.scanf("R%hu", &n) > 0) {
					str.left_color.set_hsv(0+n*24,255,null);
					str.right_color.set_hsv(0+n*24,255,null);
					str.notify_property("left_color");
					str.notify_property("right_color");
				}
				if(interpreted_key_code == "G") {
					str.left_color.set_hsv(120,255,null);
					str.right_color.set_hsv(120,255,null);
					str.notify_property("left_color");
					str.notify_property("right_color");
				}
				if(interpreted_key_code.scanf("G%hu", &n) > 0) {
					str.left_color.set_hsv(120+n*24,255,null);
					str.right_color.set_hsv(120+n*24,255,null);
					str.notify_property("left_color");
					str.notify_property("right_color");
				}
				if(interpreted_key_code == "B") {
					str.left_color.set_hsv(240,255,null);
					str.right_color.set_hsv(240,255,null);
					str.notify_property("left_color");
					str.notify_property("right_color");
				}
				if(interpreted_key_code.scanf("B%hu", &n) > 0) {
					str.left_color.set_hsv(240+n*24,255,null);
					str.right_color.set_hsv(240+n*24,255,null);
					str.notify_property("left_color");
					str.notify_property("right_color");
				}
				if(interpreted_key_code == "W") {
					str.left_color.set_hsv(0,0,null);
					str.right_color.set_hsv(0,0,null);
					str.notify_property("left_color");
					str.notify_property("right_color");
				}
				
				if(interpreted_key_code == "ON") {
					seconds.width = (seconds.width + 1) % 60;
				}
				if(interpreted_key_code == "OFF") {
					seconds.width = (seconds.width + 59) % 60;
				}
				
				if(interpreted_key_code == "FADE" && repetition_number == 0) {
					seconds.smooth = !seconds.smooth;
				}
				
			});
		} catch( Error e) {
			stderr.printf("Error: %s\n", e.message);
			return 1;
		}
		*/
		try {
			Thread<int> thread = new Thread<int>.try("Ws2812bDriver", () => { return driver.start(renderer); });
			
			Buzzer.beep(100,2000,10);
			Buzzer.beep(400,4000,10);
			
			
			loop.run();
			
			
			stdout.puts("Terminating. Waiting for threads...\n");
			
			thread.join();
			
			Buzzer.beep(100,4000,10);
			Buzzer.beep(100,2000,10);
			
		} catch ( Error e ) {
			stderr.printf("Thread error: %s", e.message);
			return 1;
		}
		
		stdout.puts("Bye!\n");
		
		return 0;
    }
	
	public static bool shutdown() {
		Thread.usleep(1000000);
		cancellable.cancel();
		loop.quit();
		
		return Source.REMOVE;
	}
}

