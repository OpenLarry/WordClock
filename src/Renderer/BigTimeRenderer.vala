using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.BigTimeRenderer : ClockRenderer {
	private LedDriver driver;
	
	public uint8 brightness = 255;
	public bool background = true;
	
	private uint16[] NUMBERS_35 = {
		0x7B6F, 0x1749, 0x73E7, 0x73CF, 0x5BC9, 0x79CF, 0x79EF, 0x7292, 0x7BEF, 0x7BCF, 
	};
	
	public BigTimeRenderer( LedDriver driver, ClockWiring wiring ) {
		base(wiring);
		this.driver = driver;
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
		
		render_number(leds_matrix, (uint8) time.get_hour()/10, 2, 0, 120);
		render_number(leds_matrix, (uint8) time.get_hour()%10, 6, 0, 120);
		render_number(leds_matrix, (uint8) time.get_minute()/10, 2, 5, 240);
		render_number(leds_matrix, (uint8) time.get_minute()%10, 6, 5, 240);
		
		// seconds
		for(int i=0;i<leds_seconds.length;i++) {
			if(time.get_second() == i) {
				leds_seconds[i].set_hsv( 0, 255, this.brightness );
			}else{
				leds_seconds[i].set_hsv( 0, 0, (background) ? this.brightness/10 : 0 );
			}
		}
		
		return true;
	}
	
	public void render_number( Color[,] leds_matrix, uint8 number, uint8 x, uint8 y, uint16 h ){
		for(int8 i = 14;i>=0;i--) {
			if((bool) NUMBERS_35[number] & 1 << i) {
				int _x = x+(2-i%3);
				int _y = y+(4-i/3);
				if(_x < 0 || _x > 10 || _y < 0 || _y > 9) continue;
				leds_matrix[ _x, _y ].set_hsv(h,255,this.brightness); 
			}
		}
	}
}
