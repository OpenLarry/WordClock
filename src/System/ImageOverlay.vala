using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.ImageOverlay : GLib.Object, Jsonable {
	public Color background_color {
		get { return this.background_renderer.color; }
		set { this.background_renderer.color = value; }
	}
	
	protected ClockRenderer renderer;
	protected ImageRenderer image_renderer = new ImageRenderer();
	protected ColorRenderer background_renderer = new ColorRenderer();
	
	construct {
		this.image_renderer.animation = true;
		this.image_renderer.mosaic = true;
		this.image_renderer.x_offset = 0;
		this.image_renderer.y_offset = 0;
	}
	
	public ImageOverlay( ClockRenderer renderer ) {
		this.renderer = renderer;
	}
	
	public async ClockRenderer.ReturnReason image( string path, int x_speed = 0, int y_speed = 4, int count = 1, Cancellable? cancellable = null ) {
		debug("Display image: %s", path);
		
		this.image_renderer.reset();
		this.image_renderer.path = path;
		this.image_renderer.x_speed = x_speed;
		this.image_renderer.y_speed = y_speed;
		this.image_renderer.count = count;
		
		
		ClockRenderer.ReturnReason reason = yield this.renderer.overwrite( { this.background_renderer, this.image_renderer }, { this.background_renderer }, { this.background_renderer }, cancellable );
		
		debug("Display image finished");
		return reason;
	}
	
	public Cancellable display( string path, int x_speed = 0, int y_speed = 4, int count = 1, Cancellable cancellable = new Cancellable() ) {
		this.image.begin( path, x_speed, y_speed, count, cancellable );
		return cancellable;
	}
}
