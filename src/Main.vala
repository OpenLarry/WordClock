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
		
		var cancellable = new Cancellable();
		var driver = new Ws2812bDriver( {4,5,6}, 60, cancellable );
		var renderer = new ClockRenderer(new MarkusClockWiring(),driver);
		
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
		
		
		var settings = new Settings(seconds);
		settings.add_object( seconds, "default" );
		settings.add_object( bigtime, "default" );
		settings.add_object( time, "default" );
		
		MainLoop loop = new MainLoop();
		
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
		bool toggle = true;
		
		try{
			var context = new Lirc.Context("wordclock-remote");
			var listener = new Lirc.Listener(context, loop.get_context());
		
			listener.button.connect((device_conf, interpreted_key_code, repetition_number) => {
				if(repetition_number == 0) Buzzer.beep(10);
				
				if(interpreted_key_code == "STROBE" && repetition_number == 0) {
					if(toggle) {
						renderer.activate("BigTime","Black","Seconds");
					}else{
						renderer.activate("Time","Time","Seconds");
					}
					toggle = !toggle;
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
			Thread<int> mainThread = new Thread<int>.try("MainLoop", () => { loop.run(); return 0; });
			
			renderer.activate("TestSequence","TestSequence","TestSequence");
			Thread<int> thread = new Thread<int>.try("Ws2812bDriver", () => { return driver.start(renderer); });
			
			
			Buzzer.beep(100,2000,10);
			Buzzer.beep(400,4000,10);
			
			thread.join();
			
			while(true) {
				cancellable.reset();
				renderer.activate("Time","Time","Seconds");
				thread = new Thread<int>.try("Ws2812bDriver", () => { return driver.start(renderer); });
				thread.join();
			}
			
			mainThread.join();
		} catch ( Error e ) {
			stderr.printf("Thread error: %s", e.message);
			return 1;
		}
		
		//stdout.puts("Terminating. Waiting for threads...\n");
		
		
		stdout.puts("Bye!\n");
		
		return 0;
    }
}

