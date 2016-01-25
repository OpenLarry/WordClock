using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.ImageRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer {
	public string path {
		owned get {
			return this.real_path;
		}
		set {
			this.real_path = value;
			this.surface = SDLImage.load(value);
			if(this.surface != null) this.surface.do_lock();
		}
		default = "image.png";
	}
	
	protected string real_path;
	protected SDL.Surface surface;
	
	public bool render_matrix( Color[,] matrix ) {
		if(this.surface == null || this.surface.w != matrix.length[0] || this.surface.h != matrix.length[1]) return true;
		
		for(int y=0;y<this.surface.h;y++) {
			for(int x=0;x<this.surface.w;x++) {
				uint8 r=0,g=0,b=0,a=0;
				uint8* pixel_base = ((uint8*) this.surface.pixels + y * this.surface.pitch + x * this.surface.format.BytesPerPixel);
				
				uint32 pixel = 0;
				for(int i=0;i<this.surface.format.BytesPerPixel;i++) {
					pixel |= pixel_base[i] << 8*i;
				}
				
				this.surface.format.get_rgba( pixel, ref r, ref g, ref b, ref a );
				
				matrix[x,y].mix_with( new Color.from_rgb(r,g,b), a );
			}
		}
		
		
		return true;
	}
}
