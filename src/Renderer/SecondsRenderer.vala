using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.SecondsRenderer : GLib.Object, ClockRenderable, BacklightRenderer {
	public uint8 brightness = 255;
	public bool background = true;
	
	public uint8[] get_fps_range() {
		return {10,uint8.MAX};
	}
	
	public bool render_backlight( Color[] leds_backlight ) {
		var time = new DateTime.now_local();
		
		// seconds
		for(int i=0;i<leds_backlight.length;i++) {
			if(time.get_second() == i) {
				leds_backlight[i].set_hsv((uint16) time.get_minute()*6 + time.get_second()/10, 255, this.brightness);
			}else{
				leds_backlight[i].set_hsv(0, 0, (background) ? this.brightness/10 : 0);
			}
		}
		
		return true;
	}
}
