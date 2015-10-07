using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.TimeRenderer : ClockWiringRenderer {
	private LedDriver driver;
	private FrontPanel frontpanel;
	
	public TimeRenderer( FrontPanel frontpanel, LedDriver driver, ClockWiring wiring ) {
		base(wiring);
		this.driver = driver;
		this.frontpanel = frontpanel;
	}
	
	/**
	 * Renders time
	 * @param leds Array of LED RGB values
	 * @return Continue
	 */
	public override bool render_clock( Color[,] leds_matrix, Color[] leds_minutes, Color[] leds_seconds ) {
		// clear
		driver.clearLEDs();
		
		var time = new DateTime.now_local();
		
		// words
		var words = this.frontpanel.getTime((uint8) time.get_hour(),(uint8) time.get_minute());
		for(int i=0;i<words.length[0];i++) {
			for(int j=0;j<words[i,2];j++) {
				leds_matrix[words[i,0]+j,words[i,1]].r = 100;
				leds_matrix[words[i,0]+j,words[i,1]].g = 100;
				leds_matrix[words[i,0]+j,words[i,1]].b = 100;
			}
		}
		
		// minutes
		for(int i=0;i<4;i++) {
			if(i<time.get_minute()%5) {
				leds_minutes[i].r = 100;
				leds_minutes[i].g = 100;
				leds_minutes[i].b = 100;
			}else{
				leds_minutes[i].r = 0;
				leds_minutes[i].g = 0;
				leds_minutes[i].b = 0;
			}
		}
		
		// seconds
		for(int i=0;i<leds_seconds.length;i++) {
			if(time.get_second() == i) {
				leds_seconds[i].r = 255;
				leds_seconds[i].g = 255;
				leds_seconds[i].b = 255;
			}else{
				leds_seconds[i].r = 20;
				leds_seconds[i].g = 20;
				leds_seconds[i].b = 20;
			}
		}
		
		return true;
	}
}
