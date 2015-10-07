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
		
		var driver = new Ws2812bDriver( {4,5,6}, 60, 30 );
		var frontpanel = new RhineRuhrGermanFrontPanel();
		var wiring = new MarkusClockWiring();
		
		MainLoop loop = new MainLoop();
		var buzzer = new Buzzer();
		
		try{
			var context = new Lirc.Context("wordclock-remote");
			var listener = new Lirc.Listener(context, loop.get_context());
		
			listener.button.connect((device_conf, interpreted_key_code, repetition_number) => {
				buzzer.beep(2000,255,100);
				stdout.printf("%s %s %u", device_conf, interpreted_key_code, repetition_number);
			});
		} catch( Error e) {
			stderr.printf("Error: %s\n", e.message);
			return 1;
		}
		
		try {
			Thread<int> thread = new Thread<int>.try("Ws2812bDriver", () => { return driver.start(new TestSequenceRenderer(driver, wiring)); });
			
			buzzer.beep(2000,255,100);
			buzzer.beep(4000,255,100);
			
			thread.join();
			
			thread = new Thread<int>.try("Ws2812bDriver", () => { return driver.start(new TimeRenderer(frontpanel, driver, wiring)); });
		} catch ( Error e ) {
			stderr.printf("Thread error: %s", e.message);
			return 1;
		}
		
		
		loop.run();
		
		//stdout.puts("Terminating. Waiting for threads...\n");
		
		
		stdout.puts("Bye!\n");
		
		return 0;
    }
}

