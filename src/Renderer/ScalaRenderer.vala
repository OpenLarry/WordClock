using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.ScalaRenderer : GLib.Object, Jsonable, ClockRenderable, BacklightRenderer {
	public uint8 interval { get; set; default = 5; }
	public uint8 width { get; set; default = 1; }
	public uint8 offset { get; set; default = 0; }
	public Color color { get; set; default = new Color.from_hsv( 0, 255, 70 ); }
	
	public bool render_backlight( Color[] leds_backlight ) {
		for(int i=0;i<leds_backlight.length;i++) {
			if(i%this.interval<this.width) {
				leds_backlight[(i+this.offset+leds_backlight.length)%leds_backlight.length].mix_with(color, 255);
			}
		}
		
		return true;
	}
}
