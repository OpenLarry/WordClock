using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Main : GLib.Object {
	public static Gpio button0;
	public static Gpio button1;
	public static Gpio button2;
	public static Gpio pir;
	
	private static ClockRenderer renderer;
	private static Cancellable cancellable;
	private static MainLoop loop;
	
    public static int main(string[] args) {
		if( !Thread.supported() ) {
			stderr.printf("Cannot run without threads.\n");
			return -1;
		}
		
		stdout.puts("Wordclock 1.0\n\n");
		
		
		
		try{
			stdout.puts("Starting REST server...\n");
			new RestServer( );
			stdout.puts("Running!\n");
		} catch( Error e ) {
			stdout.printf("Error %s\n", e.message);
		}
		
		/*Thread<int> thread;
		try {
			thread = new Thread<int>.try("REST-Server", rest.run);
		} catch ( Error e ) {
			stderr.printf("Thread error: %s", e.message);
			return 1;
		}*/
		
		cancellable = new Cancellable();
		var driver = new Ws2812bDriver( {4,5,6}, 60, cancellable );
		renderer = new ClockRenderer(new MarkusClockWiring(),driver);
		
		var frontpanel = new RhineRuhrGermanFrontPanel();
		var time = new TimeRenderer(frontpanel);
		renderer.add_matrix_renderer("Time", time);
		renderer.add_dots_renderer("Time", time);
		
		var seconds = new SecondsRenderer();
		renderer.add_backlight_renderer("Seconds", seconds);
		
		var bigtime = new BigTimeRenderer();
		renderer.add_matrix_renderer("BigTime", bigtime);
		
		var testseq = new TestSequenceRenderer();
		renderer.add_matrix_renderer("TestSequence", testseq);
		renderer.add_dots_renderer("TestSequence", testseq);
		renderer.add_backlight_renderer("TestSequence", testseq);
		
		var black = new ColorRenderer();
		renderer.add_matrix_renderer("Black", black);
		renderer.add_dots_renderer("Black", black);
		renderer.add_backlight_renderer("Black", black);
		
		var str = new StringRenderer(() => { return new DateTime.now_local().format("%k:%M ").chug(); }, new StringRendererMicrosoftSansSerif());
		renderer.add_matrix_renderer("String", str);
		
		var settings = new Settings(seconds);
		settings.add_object( seconds, "default" );
		settings.add_object( bigtime, "default" );
		settings.add_object( time, "default" );
		settings.add_object( str, "default" );
		
		loop = new MainLoop();
		
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
		pir = new Gpio(7);
		
		button0.update.connect((value) => {
			Buzzer.beep(100,(value)?2500:1500,255);
		});
		button1.update.connect((value) => {
			Buzzer.beep(100,(value)?2500:1500,255);
		});
		button2.update.connect((value) => {
			Buzzer.beep(100,(value)?2500:1500,255);
		});
		pir.update.connect((value) => {
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
					switch(toggle%3) {
						case 0:
							renderer.activate("BigTime","Black","Seconds");
						break;
						case 1:
							renderer.activate("Time","Time","Seconds");
						break;
						case 2:
							renderer.activate("String","Black","Seconds");
						break;
					}
					toggle += 1;
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
					
					
					seconds.seconds_color = new Color.from_hsv(0,255,brightness);
					seconds.background_color = new Color.from_hsv(0,0,(background) ? brightness : 0);
					bigtime.hours_color = new Color.from_hsv(100,255,brightness);
					bigtime.minutes_color = new Color.from_hsv(140,255,brightness);
					time.words_color = new Color.from_hsv(0,255,brightness);
					time.dots_color = new Color.from_hsv(0,255,brightness);
					str.left_color = new Color.from_hsv(0,255,brightness);
					str.right_color = new Color.from_hsv(120,255,brightness);
				}
				if(interpreted_key_code == "DOWN") {
					if(brightness - repetition_number-1 < 0) {
						brightness = 0;
					}else{
						brightness -= repetition_number+1;
					}
					
					seconds.seconds_color = new Color.from_hsv(0,255,brightness);
					seconds.background_color = new Color.from_hsv(0,0,(background) ? brightness : 0);
					bigtime.hours_color = new Color.from_hsv(100,255,brightness);
					bigtime.minutes_color = new Color.from_hsv(140,255,brightness);
					time.words_color = new Color.from_hsv(0,255,brightness);
					time.dots_color = new Color.from_hsv(0,255,brightness);
					str.left_color = new Color.from_hsv(0,255,brightness);
					str.right_color = new Color.from_hsv(120,255,brightness);
				}
				
				if(interpreted_key_code == "R") {
					str.speed -= 1;
				}
				if(interpreted_key_code == "G") {
					str.speed += 1;
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
		
		try {
			renderer.activate("TestSequence","TestSequence","TestSequence");
			Thread<int> thread = new Thread<int>.try("Ws2812bDriver", () => { return driver.start(renderer); });
			
			
			Buzzer.beep(100,2000,10);
			Buzzer.beep(400,4000,10);
			
			thread.join();
			
			renderer.activate("String","Black","Seconds");
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
		renderer.activate("Black","Black","Black");
		Thread.usleep(1000000);
		cancellable.cancel();
		loop.quit();
		
		return Source.REMOVE;
	}
}

