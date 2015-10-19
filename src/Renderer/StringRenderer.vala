using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.StringRenderer : GLib.Object, ClockRenderable, MatrixRenderer {
	public Color background_color { get; set; default = new Color.from_hsv( 0, 0, 0 ); }
	public Color left_color { get; set; default = new Color.from_hsv( 0, 255, 35 ); }
	public Color right_color { get; set; default = new Color.from_hsv( 120, 255, 35 ); }
	public uint8 speed { get; set; default = 10; }
	
	protected GLib.Settings settings;
	
	protected uint8[] bitmaps;
	protected uint16[,] descriptors;
	protected uint8 height;
	protected uint8 offset;
	
	protected uint16[] rendered_str;
	protected string str;
	
	public delegate string StringFunc();
	protected StringFunc str_func;
	
	public StringRenderer( owned StringFunc str_func, StringRendererFont font ) {
		this.str_func = (owned) str_func;
		
		this.bitmaps = font.get_bitmaps();
		this.descriptors = font.get_descriptors();
		this.height = font.get_height();
		this.offset = font.get_offset();
	}
	
	public uint8[] get_fps_range() {
		return {this.speed,uint8.MAX};
	}

	
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
		};
		
		
		var time = new DateTime.now_local();
		
		string str = this.str_func();
		
		if(str != this.str) {
			this.str = str;
			this.rendered_str = render_str(str);
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
	
	public uint16[] render_str( string s, uint8[]? monospace = null, bool space = true, uint16? constwidth = null ){
		uint16[] r = {};
		
		string str;
		try {
			str = GLib.convert(s, s.length, "ISO-8859-1", "UTF-8");
		} catch( Error e ) {
			stderr.printf("Error: %s\n", e.message);
			return r;
		}
		
		for(uint16 i=0;i<str.length;i++) {
			if( str.@get(i) == ' ' ) {
				r += 0x0000;
				r += 0x0000;
				r += 0x0000;
				r += 0x0000;
				continue;
			}
			if( str.@get(i) < 33 || str.@get(i)-33 >= this.descriptors.length[0] ) continue;
			
			var width = this.descriptors[str.@get(i)-33,0];
			var offset = this.descriptors[str.@get(i)-33,1];
			
			if(width == 0) continue;
			
			if(monospace != null && width < monospace[i]) {
				for(uint8 j=0;j<(monospace[i]-width)/2;j++) {
					r += 0x0000;
				}
			}
			
			for(uint16 j=0; j<width; j++) {
				uint16 col = 0x0000;
				for(uint8 k=0; k<this.height-this.offset; k++) {
					if((bool) (this.bitmaps[offset+j/8+(k+this.offset)*((width-1)/8+1)] & (0x80 >> (j%8))))
						col |= 0x0001 << k;
				}
				r += col;
			}
			
			if(monospace != null && width < monospace[i]) {
				for(uint8 j=0;j<(monospace[i]-width)/2+(monospace[i]-width)%2;j++) {
					r += 0x0000;
				}
			}
			
			if(space) {
				r += 0x0000;
			}
		}
		
		for(int i=r.length;i<(constwidth ?? 0);i++) {
			r += 0x0000;
		}
		
		return r;
	}
}