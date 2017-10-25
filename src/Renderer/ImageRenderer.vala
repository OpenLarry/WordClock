using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.ImageRenderer : CairoRenderer, Jsonable {
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
	public bool animation {
		get { return this.x_stepsize == 11 && this.y_stepsize == 10; }
		set { this.x_stepsize = value ? 11 : 1; this.y_stepsize = value ? 10 : 1; }
	}
	
	private string real_path;
	private Cairo.ImageSurface? surface = null;
	
	protected override Cairo.ImageSurface? render_surface( ) {
		lock(this.surface) {
			if(this.surface != null) return this.surface;
		}
		
		return null;
	}
}
