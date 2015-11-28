using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.SecondsRenderer : GLib.Object, Jsonable, ClockRenderable, BacklightRenderer {
	public bool smooth { get; set; default = true; }
	public uint8 width { get; set; default = 3; }
	
	public Color seconds_color { get; set; default = new Color.from_hsv( 0, 255, 255 ); }
	
	protected GLib.Settings settings;
	
	public uint8[] get_fps_range() {
		return {25,uint8.MAX};
	}
	
	public bool render_backlight( Color[] leds_backlight ) {
		var time = new DateTime.now_local();
		
		// seconds
		if(this.width > 0) {
			// floor microseconds 
			if(!this.smooth) {
				time = time.add_seconds( -Math.fmod(time.get_seconds(),1.0) );
			}
			
			// center even number of LEDs
			if(this.width % 2 == 0 ) {
				time = time.add_seconds( 0.5);
			}
			var fade = (uint8) (time.get_microsecond() / 3907);
			
			// mix with seconds color, do fading
			leds_backlight[(time.get_second()-this.width/2+60          )%60].mix_with( seconds_color, 255-fade, false);
			for(int i=1;i<this.width;i++) {
				leds_backlight[(time.get_second()-this.width/2+60+i)%60].mix_with( seconds_color, 255 );
			}
			leds_backlight[(time.get_second()+this.width/2+this.width%2)%60].mix_with( seconds_color, fade, false);
		}
		
		return true;
	}
}
