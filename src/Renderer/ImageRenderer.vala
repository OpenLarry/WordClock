using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.ImageRenderer : CairoRenderer, Jsonable, ClockRenderable, MatrixRenderer {
	public string path {
		owned get {
			return this.real_path;
		}
		set {
			lock(this.surface) {
				this.real_path = value;
				
				if(value == "") {
					this.surface = null;
					return;
				}
				
				this.surface = new Cairo.ImageSurface.from_png(value);
				if(this.surface.status() != Cairo.Status.SUCCESS) {
					warning("Cairo error: %s (%s)", this.surface.status().to_string(), value);
					this.surface = null;
				}
			}
		}
		default = "";
	}
	private string real_path;
	private Cairo.ImageSurface? surface = null;
	
	public bool render_matrix( Color[,] matrix ) {
		lock(this.surface) {
			if(this.surface != null) this.render_surface_to_matrix( matrix, this.surface );
		}
		
		return true;
	}
}
