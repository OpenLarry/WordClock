using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.ClockRenderer : GLib.Object, FrameRenderer {
	private Wiring wiring;
	private LedDriver driver;
	
	public ClockRenderer( LedDriver driver, Wiring wiring ) {
		this.driver = driver;
		this.wiring = wiring;
	}
	
	/**
	 * Renders time
	 * @param leds Array of LED RGB values
	 */
	public void render( uint8[,,] leds ) {
		var panel = new RhineRuhrGermanFrontPanel();
		
		// clear
		driver.clearLEDs();
		
		// map wiring
		var leds_matrix = wiring.getMatrix( leds );
		var leds_minutes = wiring.getMinutes( leds );
		var leds_seconds = wiring.getSeconds( leds );
		
		var time = new DateTime.now_local();
		
		// words
		var words = panel.getTime((uint8) time.get_hour(),(uint8) time.get_minute());
		for(int i=0;i<words.length[0];i++) {
			for(int j=0;j<words[i,2];j++) {
				*leds_matrix[words[i,0]+j,words[i,1],0] = 100;
				*leds_matrix[words[i,0]+j,words[i,1],1] = 100;
				*leds_matrix[words[i,0]+j,words[i,1],2] = 100;
			}
		}
		
		// seconds
		for(int i=0;i<leds_seconds.length[0];i++) {
			if(time.get_second() == i) {
				*leds_seconds[i,0] = 255;
				*leds_seconds[i,1] = 255;
				*leds_seconds[i,2] = 255;
			}else{
				*leds_seconds[i,0] = 20;
				*leds_seconds[i,1] = 20;
				*leds_seconds[i,2] = 20;
			}
		}
		
		// minutes
		for(int i=0;i<4;i++) {
			*leds_minutes[i,0] = (i<time.get_minute()%5) ? 100 : 0;
			*leds_minutes[i,1] = (i<time.get_minute()%5) ? 100 : 0;
			*leds_minutes[i,2] = (i<time.get_minute()%5) ? 100 : 0;
		}
	}
}
