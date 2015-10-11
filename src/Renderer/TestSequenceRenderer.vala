using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.TestSequenceRenderer : GLib.Object, ClockRenderable, MatrixRenderer, DotsRenderer, BacklightRenderer {
	private uint8 i=0;
	
	public uint8[] get_fps_range() {
		return { 30, 30 };
	}
	
	/**
	 * Renders time
	 * @param leds Array of LED RGB values
	 * @return Continue
	 */
	public bool render_matrix( Color[,] leds_matrix ) {
		ClockRenderer.clear_leds_matrix( leds_matrix );
		
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
		
		return true;
	}
	
	public bool render_dots( Color[] leds_dots ) {
		leds_dots[0].set_hsv( 0, 0, 255 );
		leds_dots[1].set_hsv( 0, 0, 255 );
		leds_dots[2].set_hsv( 0, 0, 255 );
		leds_dots[3].set_hsv( 0, 0, 255 );
		
		return true;
	}
	
	public bool render_backlight( Color[] leds_backlight ) {
		for(int i=0;i<60;i++) {
			leds_backlight[i].set_hsv( 0, 0, 255 );
		}
		
		if(this.i++==109) return false;
		
		return true;
	}
}
