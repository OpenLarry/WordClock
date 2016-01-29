using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.StringRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer {
	public Color left_color { get; set; default = new Color.from_hsv( 0, 0, 200 ); }
	public Color right_color { get; set; default = new Color.from_hsv( 0, 0, 200 ); }
	public uint8 speed { get; set; default = 10; }
	public uint8 add_spacing { get; set; default = 0; }
	
	public string font_name {
		owned get {
			return this.font.get_class().get_type().name();
		}
		set {
			this.font = (Font) Object.new( Type.from_name( value ) );
			this.last_str = "";
		}
	}
	
	public bool time_format { get; set; default = true; }
	public string string { get; set; default = "%k:%M "; }
	
	public int count = -1;
	
	protected Font font = new MicrosoftSansSerifFont();
	
	protected uint16[] rendered_str;
	protected string last_str;
	protected int64 start_time = 0;
	
	public uint8[] get_fps_range() {
		return {this.speed,uint8.MAX};
	}

	
	/**
	 * Renders time
	 * @param leds Array of LED RGB values
	 * @return Continue
	 */
	public bool render_matrix( Color[,] leds_matrix ) {
		var time = new DateTime.now_local();
		
		string str;
		if(this.time_format) {
			str = time.format(this.string).chug();
		}else{
			str = this.string;
		}
		
		if(str != this.last_str) {
			this.last_str = str;
			this.rendered_str = this.font.render_str(str, add_spacing);
		}
		
		
		var pos = ((get_monotonic_time() - this.start_time)/(1000000/this.speed)) - leds_matrix.length[0] + 1;
		if(pos >= this.rendered_str.length) {
			if(count >= 0 && count-- == 0) return false;
			
			this.start_time = get_monotonic_time();
			pos = -leds_matrix.length[0] + 1;
		}
		
		for(int i=0; i<leds_matrix.length[0]; i++) {
			for(int j=0;j<leds_matrix.length[1]; j++) {
				if(pos+i >= 0 && pos+i < this.rendered_str.length && (bool) (this.rendered_str[pos+i] & (0x0001 << j)))
					leds_matrix[i,j].mix_with(this.left_color.clone().mix_with(this.right_color, (uint8) (pos+i)*255/this.rendered_str.length), 255);
			}
		}
		
		return true;
	}
	
}
