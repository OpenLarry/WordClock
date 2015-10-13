using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Main : GLib.Object {

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
				}
				
				if(interpreted_key_code == "UP") {
					brightness += 8;
				}
				if(interpreted_key_code == "DOWN") {
					brightness -= 8;
				}
				
				
				if(interpreted_key_code == "ON") {
					seconds.width = (seconds.width + 1) % 60;
				}
				if(interpreted_key_code == "OFF") {
					seconds.width = (seconds.width + 59) % 60;
				}
				
				if(interpreted_key_code == "FADE") {
					seconds.smooth = !seconds.smooth;
				}
				
				seconds.seconds_color = new Color.from_hsv(0,255,brightness);
				seconds.background_color = new Color.from_hsv(0,0,(background) ? brightness/10 : 0);
				bigtime.hours_color = new Color.from_hsv(100,255,brightness/2);
				bigtime.minutes_color = new Color.from_hsv(140,255,brightness/2);
				time.words_color = new Color.from_hsv(0,255,brightness/2);
				time.dots_color = new Color.from_hsv(0,255,brightness/2);
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

