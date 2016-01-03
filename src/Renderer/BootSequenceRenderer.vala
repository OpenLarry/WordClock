using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.BootSequenceRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer, DotsRenderer, BacklightRenderer {
	private uint frame=0;
	private StringRenderer str_renderer = new StringRenderer();
	
	public uint8[] get_fps_range() {
		return { 30, 30 };
	}
	
	/**
	 * Renders boot sequence
	 * @param leds Array of LED RGB values
	 * @return Continue
	 */
	public bool render_matrix( Color[,] leds_matrix ) {
		if(this.frame <= 25) {
			for(int i=0; i<leds_matrix.length[0]; i++) {
				for(int j=0; j<leds_matrix.length[1]; j++) {
					leds_matrix[i,j].set_hsv( 0, 0, (uint8) (this.frame*10) );
				}
			}
			return true;
		}else if(this.frame <= 50) {
			for(int i=0; i<leds_matrix.length[0]; i++) {
				for(int j=0; j<leds_matrix.length[1]; j++) {
					leds_matrix[i,j].set_hsv( 0, 0, (uint8) (500-this.frame*10) );
				}
			}
			
			return true;
		}else if(this.frame == 51) {
			this.str_renderer.time_format = false;
			this.str_renderer.string = @"WordClock $(Version.GIT_DESCRIBE)";
			this.str_renderer.count = 1;
			this.str_renderer.left_color.set_hsv(120, 255, 255);
			this.str_renderer.right_color.set_hsv(240, 255, 255);
			
			return this.str_renderer.render_matrix( leds_matrix );
		}else{
			return this.str_renderer.render_matrix( leds_matrix );
		}
	}
	
	public bool render_dots( Color[] leds_dots ) {
		if(this.frame <= 25) {
			for(int i=0; i<leds_dots.length; i++) {
				leds_dots[i].set_hsv( 0, 0, (uint8) (this.frame*10) );
			}
		}else if(this.frame <= 50) {
			for(int i=0; i<leds_dots.length; i++) {
				leds_dots[i].set_hsv( 0, 0, (uint8) (500-this.frame*10) );
			}
		}
		
		return true;
	}
	
	public bool render_backlight( Color[] leds_backlight ) {
		if(this.frame > 50 && this.frame <= 75) {
			for(int i=0;i<leds_backlight.length;i++) {
				leds_backlight[i].set_hsv( 0, 0, (uint8) (this.frame*10-500) );
			}
		}else if(this.frame > 75) {
			for(int i=0;i<leds_backlight.length;i++) {
				leds_backlight[i].set_hsv( 0, 0, 255 );
			}
			leds_backlight[(leds_backlight.length+this.frame-74)%leds_backlight.length].set_hsv( (uint16) ((this.frame*3) % 360), 255, 255 );
			leds_backlight[(leds_backlight.length+this.frame-75)%leds_backlight.length].set_hsv( (uint16) ((this.frame*3) % 360), 255, 255 );
			leds_backlight[(leds_backlight.length+this.frame-76)%leds_backlight.length].set_hsv( (uint16) ((this.frame*3) % 360), 255, 255 );
			leds_backlight[(leds_backlight.length+this.frame-77)%leds_backlight.length].set_hsv( (uint16) ((this.frame*3) % 360), 255, 255 );
			leds_backlight[(leds_backlight.length+this.frame-78)%leds_backlight.length].set_hsv( (uint16) ((this.frame*3) % 360), 255, 255 );
		}
		
		this.frame++;
		
		return true;
	}
}
