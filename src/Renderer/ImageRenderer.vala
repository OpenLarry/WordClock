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
			lock(this.colors) {
				this.real_path = value;
				
				SDL.Surface surface = SDLImage.load(value);
				
				if(surface != null) {
					surface.do_lock();
					
					this.colors = new Color[surface.w,surface.h];
					this.alpha = new uint8[surface.w,surface.h];
					
					for(int y=0;y<surface.h;y++) {
						for(int x=0;x<surface.w;x++) {
							uint8 r=0,g=0,b=0,a=0;
							uint8* pixel_base = ((uint8*) surface.pixels + y * surface.pitch + x * surface.format.BytesPerPixel);
							
							uint32 pixel = 0;
							for(int i=0;i<surface.format.BytesPerPixel;i++) {
								pixel |= pixel_base[i] << 8*i;
							}
							
							surface.format.get_rgba( pixel, ref r, ref g, ref b, ref a );
							
							this.colors[x,y] = new Color.from_rgb(r,g,b);
							this.alpha[x,y] = a;
						}
					}
				}else{
					this.colors = null;
					this.alpha = null;
				}
			}
		}
		default = "image.png";
	}
	
	protected string real_path;
	
	protected Color[,]? colors;
	protected uint8[,]? alpha;
	
	public bool render_matrix( Color[,] matrix ) {
		lock(this.colors) {
			if(this.colors == null || this.alpha == null ||
			   this.colors.length[0] != matrix.length[0] || this.colors.length[1] != matrix.length[1] ||
			   this.alpha.length[0] != matrix.length[0] || this.alpha.length[1] != matrix.length[1]
			) return true;
			
			for(int y=0;y<this.colors.length[1];y++) {
				for(int x=0;x<this.colors.length[0];x++) {
					matrix[x,y].mix_with( this.colors[x,y], this.alpha[x,y] );
				}
			}
		}
		
		return true;
	}
}
