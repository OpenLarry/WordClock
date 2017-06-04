using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.Font : GLib.Object {
	public abstract uint8[] get_bitmaps();
	public abstract uint16[,] get_descriptors();
	public abstract uint8 get_height();
	public abstract uint8 get_offset();
	public abstract uint8 get_character_spacing();
	
	public virtual uint16[] render_str( string s, uint8 add_spacing = 0 ){
		uint16[] r = {};
		
		// convert encoding
		string str;
		try {
			str = GLib.convert(s, s.length, "ISO-8859-1", "UTF-8");
		} catch( Error e ) {
			warning(e.message);
			return r;
		}
		
		// get font parameters
		var font_bitmaps = this.get_bitmaps();
		var font_descriptors = this.get_descriptors();
		var font_height = this.get_height();
		var font_offset = this.get_offset();
		var font_character_spacing = this.get_character_spacing();
		
		// iterate over all characters
		for(uint16 i=0;i<str.length;i++) {
			// space
			if( str.@get(i) == ' ' ) {
				for(int e=0;e<3*font_character_spacing;e++) r += 0x0000;
				for(int e=0;e<add_spacing;e++) r += 0x0000;
				continue;
			}
			
			// skip characters out of range
			if( str.@get(i) < 33 || str.@get(i)-33 >= font_descriptors.length[0] ) continue;
			
			// get position
			var width = font_descriptors[str.@get(i)-33,0];
			var offset = font_descriptors[str.@get(i)-33,1];
			
			// skip non existent characters
			if(width == 0) continue;
			
			// generate bits
			for(uint16 j=0; j<width; j++) {
				uint16 col = 0x0000;
				for(uint8 k=0; k<font_height-font_offset; k++) {
					if((bool) (font_bitmaps[offset+j/8+(k+font_offset)*((width-1)/8+1)] & (0x80 >> (j%8))))
						col |= 0x0001 << k;
				}
				r += col;
			}
			
			// character spacing
			if( i<str.length-1 ) for(int e=0;e<font_character_spacing;e++) r += 0x0000;
			for(int e=0;e<add_spacing;e++) r += 0x0000;
		}
		
		return r;
	}
}
