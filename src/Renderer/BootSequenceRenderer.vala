using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.BootSequenceRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer, DotsRenderer, BacklightRenderer {
	private TextRenderer text_renderer = new TextRenderer();
	private ImageRenderer image_renderer = new ImageRenderer();
	
	private uint phase = 0;
	private uint frame = 0;
	private uint last_frame = 0;
	
	construct {
		this.image_renderer.path = "/usr/share/wordclock/bootlogo.png";
		
		this.text_renderer.time_format = false;
		this.text_renderer.markup = true;
		this.text_renderer.text = @"<span color=\"#ff0000\">W</span><span color=\"#00ff00\">o</span><span color=\"#0000ff\">r</span><span color=\"#ffff00\">d</span><span color=\"#00ffff\">C</span><span color=\"#ff00ff\">l</span><span color=\"#ff8800\">o</span><span color=\"#00ff88\">c</span><span color=\"#8800ff\">k</span> $(Version.GIT_DESCRIBE)";
		this.text_renderer.count = 1;
		this.text_renderer.color.set_hsv(0, 0, 255);
		
		/*
		 * Don't fade out boot logo after 1 minute of system uptime.
		 * Actually get_monotonic_time() isn't specified to return the system uptime,
		 * but Linux does so and vala doesn't offer a specific function to get it.
		 */
		if(get_monotonic_time() > 60000000) this.phase = 1;
	}
	
	public uint8[] get_fps_range() {
		return { 30, 30 };
	}
	
	/**
	 * Renders boot sequence
	 * @param leds Array of LED RGB values
	 * @return Continue
	 */
	public bool render_matrix( Color[,] leds_matrix ) {
		switch(this.phase) {
			case 0: // fade out boot logo
				if(this.frame > 26) {
					this.phase++;
					this.frame = 0;
					return this.render_matrix(leds_matrix);
				}
				
				this.image_renderer.render_matrix(leds_matrix);
				
				Color black = new Color.from_hsv( 0, 0, 0 );
				for(int i=0; i<leds_matrix.length[0]; i++) {
					for(int j=0; j<leds_matrix.length[1]; j++) {
						leds_matrix[i,j].mix_with(black, (uint8) uint.min( this.frame*10, 255 ));
					}
				}
				
				break;
			case 1: // fade to white
				if(this.frame > 26) {
					this.phase++;
					this.frame = 0;
					return this.render_matrix(leds_matrix);
				}
				
				for(int i=0; i<leds_matrix.length[0]; i++) {
					for(int j=0; j<leds_matrix.length[1]; j++) {
						leds_matrix[i,j].set_hsv( 0, 0, (uint8) uint.min( this.frame*10, 255 ) );
					}
				}
				
				break;
			case 2: // stay white
				if(this.frame > 50) {
					this.phase++;
					this.frame = 0;
					return this.render_matrix(leds_matrix);
				}
				
				for(int i=0; i<leds_matrix.length[0]; i++) {
					for(int j=0; j<leds_matrix.length[1]; j++) {
						leds_matrix[i,j].set_hsv( 0, 0, 255 );
					}
				}
				
				break;
			case 3: // fade to black
				if(this.frame > 26) {
					this.phase++;
					this.frame = 0;
					return this.render_matrix(leds_matrix);
				}
				
				for(int i=0; i<leds_matrix.length[0]; i++) {
					for(int j=0; j<leds_matrix.length[1]; j++) {
						leds_matrix[i,j].set_hsv( 0, 0, 255-(uint8) uint.min( this.frame*10, 255 ) );
					}
				}
				
				break;
			case 4: // show version text, fade in backlight
				if(!this.text_renderer.render_matrix( leds_matrix )) {
					this.phase++;
					this.frame = 0;
					return this.render_matrix(leds_matrix);
				}
				
				break;
			case 5: // stay black, fade out backlight
				if(this.frame > 26) {
					this.phase++;
					this.frame = 0;
					return this.render_matrix(leds_matrix);
				}
				
				for(int i=0; i<leds_matrix.length[0]; i++) {
					for(int j=0; j<leds_matrix.length[1]; j++) {
						leds_matrix[i,j].set_hsv( 0, 0, 0 );
					}
				}
				
				break;
			default:
				return false;
		}
		return true;
	}
	
	public bool render_dots( Color[] leds_dots ) {
		switch(this.phase) {
			case 1: // fade to white
				for(int i=0; i<leds_dots.length; i++) {
					leds_dots[i].set_hsv( 0, 0, (uint8) uint.min( this.frame*10, 255 ) );
				}
				break;
			case 2: // stay white
				for(int i=0; i<leds_dots.length; i++) {
					leds_dots[i].set_hsv( 0, 0, 255 );
				}
				break;
			case 3: // fade to black
				for(int i=0; i<leds_dots.length; i++) {
					leds_dots[i].set_hsv( 0, 0, 255-(uint8) uint.min( this.frame*10, 255 ) );
				}
				break;
		}
		
		return true;
	}
	
	public bool render_backlight( Color[] leds_backlight ) {
		switch(this.phase) {
			case 4: // show version text, fade in backlight
				for(int i=0;i<leds_backlight.length;i++) {
					leds_backlight[i].set_hsv( 0, 0, (uint8) uint.min( (this.frame*10), 255 ) );
				}
				leds_backlight[(leds_backlight.length+this.frame+1)%leds_backlight.length].set_hsv( (uint16) ((this.frame*3) % 360), 255, (uint8) uint.min( (this.frame*10), 255 ) );
				leds_backlight[(leds_backlight.length+this.frame+0)%leds_backlight.length].set_hsv( (uint16) ((this.frame*3) % 360), 255, (uint8) uint.min( (this.frame*10), 255 ) );
				leds_backlight[(leds_backlight.length+this.frame-1)%leds_backlight.length].set_hsv( (uint16) ((this.frame*3) % 360), 255, (uint8) uint.min( (this.frame*10), 255 ) );
				leds_backlight[(leds_backlight.length+this.frame-2)%leds_backlight.length].set_hsv( (uint16) ((this.frame*3) % 360), 255, (uint8) uint.min( (this.frame*10), 255 ) );
				leds_backlight[(leds_backlight.length+this.frame-3)%leds_backlight.length].set_hsv( (uint16) ((this.frame*3) % 360), 255, (uint8) uint.min( (this.frame*10), 255 ) );
				this.last_frame = this.frame;
				break;
			case 5: // stay black, fade out backlight
				for(int i=0;i<leds_backlight.length;i++) {
					leds_backlight[i].set_hsv( 0, 0, 255-(uint8) uint.min( (this.frame*10), 255 ) );
				}
				leds_backlight[(leds_backlight.length+this.last_frame+this.frame+1)%leds_backlight.length].set_hsv( (uint16) (((this.last_frame+this.frame)*3) % 360), 255, 255-(uint8) uint.min( (this.frame*10), 255 ) );
				leds_backlight[(leds_backlight.length+this.last_frame+this.frame+0)%leds_backlight.length].set_hsv( (uint16) (((this.last_frame+this.frame)*3) % 360), 255, 255-(uint8) uint.min( (this.frame*10), 255 ) );
				leds_backlight[(leds_backlight.length+this.last_frame+this.frame-1)%leds_backlight.length].set_hsv( (uint16) (((this.last_frame+this.frame)*3) % 360), 255, 255-(uint8) uint.min( (this.frame*10), 255 ) );
				leds_backlight[(leds_backlight.length+this.last_frame+this.frame-2)%leds_backlight.length].set_hsv( (uint16) (((this.last_frame+this.frame)*3) % 360), 255, 255-(uint8) uint.min( (this.frame*10), 255 ) );
				leds_backlight[(leds_backlight.length+this.last_frame+this.frame-3)%leds_backlight.length].set_hsv( (uint16) (((this.last_frame+this.frame)*3) % 360), 255, 255-(uint8) uint.min( (this.frame*10), 255 ) );
				break;
		}
		
		// finished frame
		this.frame++;
		
		return true;
	}
}
