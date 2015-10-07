using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.TestSequenceRenderer : ClockWiringRenderer {
	private LedDriver driver;
	
	private uint8 i=0;
	
	public TestSequenceRenderer( LedDriver driver, ClockWiring wiring ) {
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
		
		if(i<100) {
			leds_matrix[0, this.i/10].set_hsv( 0, 0, (i%10)*28 );
			leds_matrix[1, this.i/10].set_hsv( 0, 0, (i%10)*28 );
			leds_matrix[2, this.i/10].set_hsv( 0, 0, (i%10)*28 );
			leds_matrix[3, this.i/10].set_hsv( 0, 0, (i%10)*28 );
			leds_matrix[4, this.i/10].set_hsv( 0, 0, (i%10)*28 );
			leds_matrix[5, this.i/10].set_hsv( 0, 0, (i%10)*28 );
			leds_matrix[6, this.i/10].set_hsv( 0, 0, (i%10)*28 );
			leds_matrix[7, this.i/10].set_hsv( 0, 0, (i%10)*28 );
			leds_matrix[8, this.i/10].set_hsv( 0, 0, (i%10)*28 );
			leds_matrix[9, this.i/10].set_hsv( 0, 0, (i%10)*28 );
			leds_matrix[10,this.i/10].set_hsv( 0, 0, (i%10)*28 );;
		}
		if(i>9) {
			leds_matrix[0, this.i/10-1].set_hsv( 0, 0, 255-(i%10)*28 );
			leds_matrix[1, this.i/10-1].set_hsv( 0, 0, 255-(i%10)*28 );
			leds_matrix[2, this.i/10-1].set_hsv( 0, 0, 255-(i%10)*28 );
			leds_matrix[3, this.i/10-1].set_hsv( 0, 0, 255-(i%10)*28 );
			leds_matrix[4, this.i/10-1].set_hsv( 0, 0, 255-(i%10)*28 );
			leds_matrix[5, this.i/10-1].set_hsv( 0, 0, 255-(i%10)*28 );
			leds_matrix[6, this.i/10-1].set_hsv( 0, 0, 255-(i%10)*28 );
			leds_matrix[7, this.i/10-1].set_hsv( 0, 0, 255-(i%10)*28 );
			leds_matrix[8, this.i/10-1].set_hsv( 0, 0, 255-(i%10)*28 );
			leds_matrix[9, this.i/10-1].set_hsv( 0, 0, 255-(i%10)*28 );
			leds_matrix[10,this.i/10-1].set_hsv( 0, 0, 255-(i%10)*28 );
		}
		
		for(int i=0;i<60;i++) {
			leds_seconds[i].set_hsv( 0, 0, 255 );
		}
		
		leds_minutes[0].set_hsv( 0, 0, 255 );
		leds_minutes[1].set_hsv( 0, 0, 255 );
		leds_minutes[2].set_hsv( 0, 0, 255 );
		leds_minutes[3].set_hsv( 0, 0, 255 );
		
		
		if(this.i++==109) return false;
		
		return true;
	}
}
