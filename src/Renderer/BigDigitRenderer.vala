using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.BigDigitRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer {
	public Color background_color { get; set; default = new Color.from_hsv( 0, 0, 0 ); }
	public Color foreground_color { get; set; default = new Color.from_hsv( 0, 255, 200 ); }
	public string format { get; set; default = "%M"; }
	
	public string font_name {
		owned get {
			return this.font.get_class().get_type().name();
		}
		set {
			this.font = (Font) Object.new( Type.from_name( value ) );
			this.last_str_1 = 0;
			this.last_str_10 = 0;
		}
	}
	
	protected Font font = new MicrosoftSansSerifFont();
	
	protected uint16[] rendered_str_1;
	protected uint16[] rendered_str_10;
	protected char last_str_1;
	protected char last_str_10;

	
	/**
	 * Renders time
	 * @param leds Array of LED RGB values
	 * @return Continue
	 */
	public bool render_matrix( Color[,] leds_matrix ) {
		for(int i=0;i<leds_matrix.length[0];i++) {
			for(int j=0;j<leds_matrix.length[1];j++) {
				leds_matrix[i,j].mix_with(this.background_color, 255);
			}
		}
		
		
		string time = new DateTime.now(Main.timezone).format(format);
		
		char str_1 = time[1];
		char str_10 = time[0];
		
		if(str_1 != this.last_str_1) {
			this.last_str_1 = str_1;
			this.rendered_str_1 = this.font.render_str(str_1.to_string());
		}
		if(str_10 != this.last_str_10) {
			this.last_str_10 = str_10;
			this.rendered_str_10 = this.font.render_str(str_10.to_string());
		}
		
		uint margin = (5-this.rendered_str_10.length)/2+(5-this.rendered_str_10.length)%2;
		for(int i=0; i<this.rendered_str_10.length&&i<11; i++) {
			for(int j=0;j<10; j++) {
				if((bool) (this.rendered_str_10[i] & (0x0001 << j)))
					leds_matrix[margin+i,j].mix_with(this.foreground_color, 255);
			}
		}
		
		margin = 6+(5-this.rendered_str_1.length)/2;
		for(int i=0; i<this.rendered_str_1.length&&i<11; i++) {
			for(int j=0;j<10; j++) {
				if((bool) (this.rendered_str_1[i] & (0x0001 << j)))
					leds_matrix[margin+i,j].mix_with(this.foreground_color, 255);
			}
		}
		
		return true;
	}
	
}
