using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.ColorRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer, DotsRenderer, BacklightRenderer {
	public Color color { get; set; default = new Color.from_hsv( 0, 0, 0 ); }
	
	public bool render_matrix( Color[,] leds_matrix ) {
		for(int i=0;i<leds_matrix.length[0];i++) {
			for(int j=0;j<leds_matrix.length[1];j++) {
				leds_matrix[i,j].mix_with(this.color, 255);
			}
		}
		
		return true;
	}
	
	public bool render_dots( Color[] leds_dots ) {
		for(int i=0;i<leds_dots.length;i++) {
			leds_dots[i].mix_with(this.color, 255);
		}
		
		return true;
	}
	
	public bool render_backlight( Color[] leds_backlight ) {
		for(int i=0;i<leds_backlight.length;i++) {
			leds_backlight[i].mix_with(this.color, 255);
		}
		
		return true;
	}
}
