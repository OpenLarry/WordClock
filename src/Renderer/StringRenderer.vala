using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.StringRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer {
	public Color left_color { get; set; default = new Color.from_hsv( 0, 255, 35 ); }
	public Color right_color { get; set; default = new Color.from_hsv( 120, 255, 35 ); }
	public uint8 speed { get; set; default = 10; }
	
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
	
	protected GLib.Settings settings;
	
	protected Font font = new MicrosoftSansSerifFont();
	
	protected uint16[] rendered_str;
	protected string last_str;
	
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
			this.rendered_str = this.font.render_str(str);
		}
		
		
		var pos = (int) (((time.to_unix() * 1000000 + time.get_microsecond())/(1000000/this.speed)) % (this.rendered_str.length));
		
		for(int i=0; i<11; i++) {
			for(int j=0;j<10; j++) {
				if((bool) (this.rendered_str[(pos+i)%this.rendered_str.length] & (0x0001 << j)))
					leds_matrix[i,j].mix_with(this.left_color.clone().mix_with(this.right_color, (uint8) (((pos+i)%this.rendered_str.length)*255/this.rendered_str.length)), 255);
			}
		}
		
		return true;
	}
	
}
