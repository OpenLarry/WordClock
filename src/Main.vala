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
		
		
		Color test = new Color();
		test.set_hsv(120,255,100);
		stdout.printf("%u,%u,%u\n", test.r, test.g, test.b);
		
		var cancellable = new Cancellable();
		var driver = new Ws2812bDriver( {4,5,6}, 60, 30, cancellable );
		var frontpanel = new RhineRuhrGermanFrontPanel();
		var wiring = new MarkusClockWiring();
		
		var time = new TimeRenderer(frontpanel, driver, wiring);
		var bigtime = new BigTimeRenderer(driver, wiring);
		
		
		MainLoop loop = new MainLoop();
		
		try{
			var context = new Lirc.Context("wordclock-remote");
			var listener = new Lirc.Listener(context, loop.get_context());
		
			listener.button.connect((device_conf, interpreted_key_code, repetition_number) => {
				if(repetition_number == 0) Buzzer.beep(10);
				
				if(interpreted_key_code == "STROBE" && repetition_number == 0) cancellable.cancel();
				if(interpreted_key_code == "FLASH" && repetition_number == 0) {
					time.background = !time.background;
					bigtime.background = !bigtime.background;
				}
				
				if(interpreted_key_code == "UP") {
					time.brightness += 10;
					bigtime.brightness += 10;
				}
				if(interpreted_key_code == "DOWN") {
					time.brightness -= 10;
					bigtime.brightness -= 10;
				}
			});
		} catch( Error e) {
			stderr.printf("Error: %s\n", e.message);
			return 1;
		}
		
		try {
			Thread<int> mainThread = new Thread<int>.try("MainLoop", () => { loop.run(); return 0; });
			
			Thread<int> thread = new Thread<int>.try("Ws2812bDriver", () => { return driver.start(new TestSequenceRenderer(driver, wiring)); });
			
			Buzzer.beep(100,2000);
			Buzzer.beep(100,4000);
			
			thread.join();
			
			while(true) {
				cancellable.reset();
				thread = new Thread<int>.try("Ws2812bDriver", () => { return driver.start(time); });
				thread.join();
				
				cancellable.reset();
				thread = new Thread<int>.try("Ws2812bDriver", () => { return driver.start(bigtime); });
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

