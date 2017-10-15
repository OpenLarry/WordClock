using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public abstract class WordClock.CairoRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer {
	public int x_speed { get; set; default = 0; }
	public int y_speed { get; set; default = 0; }
	public int x_offset { get; set; default = 10; }
	public int y_offset { get; set; default = 9; }
	public bool mosaic { get; set; default = false; }
	
	public int count = -1;
	
	private int64 x_start_time = 0;
	private int64 y_start_time = 0;
	
	private Cairo.ImageSurface? surface;
	
	protected abstract Cairo.ImageSurface? render_surface();
	
	public bool render_matrix( Color[,] leds_matrix ) {
		Cairo.ImageSurface? surface = this.render_surface();
		if(surface != null) this.surface = surface;
		
		if(this.surface == null) {
			warning("No image for rendering");
			return false;
		}
		
		// get bytes per pixel
		int bpp = 0;
		if(this.surface.get_format() == Cairo.Format.RGB24) bpp = 3;
		if(this.surface.get_format() == Cairo.Format.ARGB32) bpp = 4;
		if(bpp == 0) {
			warning("Unsupported color format");
			return false;
		}
		
		// calc position
		int? x_pos = this.calc_offset(this.x_speed, this.x_offset, leds_matrix.length[0], this.surface.get_width(), ref this.x_start_time);
		if(x_pos == null) return false;
		int? y_pos = this.calc_offset(this.y_speed, this.y_offset, leds_matrix.length[1], this.surface.get_height(), ref this.y_start_time);
		if(y_pos == null) return false;
		
		
		// render surface to clock
		unowned uchar[] data = this.surface.get_data();
		
		for(int x=0; x<leds_matrix.length[0]; x++) {
			for(int y=0;y<leds_matrix.length[1]; y++) {
				if(this.mosaic) {
					int ptr = ((x_pos+x) % this.surface.get_width()) * 4 + ((y_pos+y) % this.surface.get_height()) * this.surface.get_stride();
					leds_matrix[x,y].mix_with_rgb(data[ptr+2],data[ptr+1],data[ptr], (bpp == 4) ? data[ptr+3] : 255);
				}else if(x_pos+x >= 0 && x_pos+x < this.surface.get_width() && y_pos+y >= 0 && y_pos+y < this.surface.get_height()) {
					int ptr = (x_pos+x) * 4 + (y_pos+y) * this.surface.get_stride();
					leds_matrix[x,y].mix_with_rgb(data[ptr+2],data[ptr+1],data[ptr], (bpp == 4) ? data[ptr+3] : 255);
				}
			}
		}
		
		return true;
	}
	
	public void reset() {
		this.x_start_time = 0;
		this.y_start_time = 0;
	}
	
	private int? calc_offset( int speed, int offset, int display_length, int surface_length, ref int64 start_time ) {
		int pos = 0;
		if(speed > 0) {
			pos = (int) ((get_monotonic_time() - start_time)/(1000000/speed));
			if(!this.mosaic) pos -= display_length - 1;
			
			if(pos >= surface_length) {
				if(this.count >= 0 && this.count-- == 0) return null;
				
				start_time = get_monotonic_time();
				pos = 0;
				if(!this.mosaic) pos -= display_length - 1;
			}
		}else{
			if(offset >= 0) {
				pos = offset;
				if(!this.mosaic) pos -= display_length - 1;
			}else{
				pos = offset + surface_length;
			}
		}
		
		return pos;
	}
}
