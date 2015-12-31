using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.WatchHandRenderer : GLib.Object, Jsonable, ClockRenderable, BacklightRenderer {
	public bool smooth { get; set; default = true; }
	public uint8 width { get; set; default = 3; }
	public int rotate_time { get; set; default = 60; }
	
	public Color color { get; set; default = new Color.from_hsv( 0, 255, 255 ); }
	
	public uint8[] get_fps_range() {
		return {25,uint8.MAX};
	}
	
	public bool render_backlight( Color[] leds_backlight ) {
		var time = new DateTime.now_local();
		
		double seconds = time.get_hour() * 3600 + time.get_minute() * 60 + time.get_seconds();
		double position = Math.fmod( seconds, this.rotate_time ) * leds_backlight.length / this.rotate_time;
		
		if(position < 0) position = leds_backlight.length + position;
		
		// seconds
		if(this.width > 0) {
			// floor microseconds 
			if(!this.smooth) {
				position = Math.floor(position);
			}
			
			// center even number of LEDs
			if(this.width % 2 == 0 ) {
				position += 0.5;
			}
			uint8 pos = (uint8) Math.floor(position);
			uint8 fade = (uint8) (Math.fmod( position, 1.0 ) * 256);
			
			// mix with seconds color, do fading
			leds_backlight[(pos-this.width/2+60          )%60].mix_with( color, 255-fade, false);
			for(int i=1;i<this.width;i++) {
				leds_backlight[(pos-this.width/2+60+i)%60].mix_with( color, 255 );
			}
			leds_backlight[(pos+this.width/2+this.width%2)%60].mix_with( color, fade, false);
		}
		
		return true;
	}
}
