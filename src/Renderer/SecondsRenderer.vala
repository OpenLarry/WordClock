using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.SecondsRenderer : GLib.Object, Jsonable, ClockRenderable, BacklightRenderer {
	public bool smooth { get; set; default = true; }
	public uint8 width { get; set; default = 3; }
	
	public Color background_color { get; set; default = new Color.from_hsv( 0, 0, 25 ); }
	public Color seconds_color { get; set; default = new Color.from_hsv( 0, 255, 255 ); }
	
	public uint background_rotate { get; set; default = 0; }
	public uint seconds_rotate { get; set; default = 3600; }
	
	protected GLib.Settings settings;
	
	public uint8[] get_fps_range() {
		return {25,uint8.MAX};
	}
	
	public bool render_backlight( Color[] leds_backlight ) {
		var time = new DateTime.now_local();
		
		// rotate hue by time
		Color background_color, seconds_color;
		if(this.background_rotate > 0) {
			background_color = this.background_color.clone().add_hue_by_time( time, this.background_rotate );
		}else{
			background_color = this.background_color;
		}
		if(this.seconds_rotate > 0) {
			seconds_color = this.seconds_color.clone().add_hue_by_time( time, this.seconds_rotate );
		}else{
			seconds_color = this.seconds_color;
		}
		
		// background
		for(int i=0;i<leds_backlight.length;i++) {
			leds_backlight[i].mix_with(background_color, 255);
		}
		
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
