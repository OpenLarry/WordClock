using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.TimeRenderer : GLib.Object, ClockRenderable, MatrixRenderer, DotsRenderer {
	private FrontPanel frontpanel;
	
	public uint8 brightness = 255;
	
	public TimeRenderer( FrontPanel frontpanel ) {
		this.frontpanel = frontpanel;
	}
	
	/**
	 * Renders time
	 * @param leds Array of LED RGB values
	 * @return Continue
	 */
	public bool render_matrix( Color[,] leds_matrix ) {
		ClockRenderer.clear_leds_matrix( leds_matrix );
		
		var time = new DateTime.now_local();
		
		// words
		var words = this.frontpanel.getTime((uint8) time.get_hour(),(uint8) time.get_minute());
		for(int i=0;i<words.length[0];i++) {
			for(int j=0;j<words[i,2];j++) {
				leds_matrix[words[i,0]+j,words[i,1]].set_hsv((uint16) time.get_hour()*24 + time.get_minute() / 4, 255, this.brightness);
			}
		}
		
		return true;
	}
	
	public bool render_dots( Color[] leds_dots ) {
		ClockRenderer.clear_leds( leds_dots );
		
		var time = new DateTime.now_local();
		
		// minutes
		for(int i=0;i<4;i++) {
			if(i<time.get_minute()%5) {
				leds_dots[i].set_hsv((uint16) time.get_hour()*24 + time.get_minute() / 4, 255, this.brightness);
			}else{
				leds_dots[i].set_hsv(0, 0, 0);
			}
		}
		
		return true;
	}
}
