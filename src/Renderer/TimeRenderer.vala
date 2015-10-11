using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.TimeRenderer : ClockRenderer {
	private LedDriver driver;
	private FrontPanel frontpanel;
	
	public uint8 brightness = 255;
	public bool background = true;
	
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
				leds_matrix[words[i,0]+j,words[i,1]].set_hsv((uint16) time.get_hour()*24 + time.get_minute() / 4, 255, this.brightness);
			}
		}
		
		// minutes
		for(int i=0;i<4;i++) {
			if(i<time.get_minute()%5) {
				leds_minutes[i].set_hsv((uint16) time.get_hour()*24 + time.get_minute() / 4, 255, this.brightness);
			}else{
				leds_minutes[i].set_hsv(0, 0, 0);
			}
		}
		
		// seconds
		for(int i=0;i<leds_seconds.length;i++) {
			if(time.get_second() == i) {
				leds_seconds[i].set_hsv((uint16) time.get_minute()*6 + time.get_second()/10, 255, this.brightness);
			}else{
				leds_seconds[i].set_hsv(0, 0, (background) ? this.brightness/10 : 0);
			}
		}
		
		return true;
	}
}
