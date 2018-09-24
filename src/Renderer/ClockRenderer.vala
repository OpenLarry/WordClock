using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.ClockRenderer : GLib.Object, FrameRenderer, Jsonable {
	private LedDriver driver;
	private ClockWiring wiring;
	
	public string active { get; set; default = ""; }
	
	public JsonableTreeMap<ClockConfiguration> configurations { get; set; default = new JsonableTreeMap<ClockConfiguration>(); }
	public JsonableTreeMap<ClockRenderable> renderers { get; set; default = new JsonableTreeMap<ClockRenderable>(); }
	
	private MatrixRenderer[]? overwrite_matrix = null;
	private DotsRenderer[]? overwrite_dots = null;
	private BacklightRenderer[]? overwrite_backlight = null;
	private SourceFunc? overwrite_callback = null;
	private Cancellable? overwrite_cancellable = null;
	
	private Color[,]? matrix = null;
	private Color[]? dots = null;
	private Color[]? backlight = null;
	
	public enum ReturnReason {
		CANCELLED,
		TERMINATED,
		REPLACED
	}
	
	public ClockRenderer( ClockWiring wiring, LedDriver driver ) {
		this.wiring = wiring;
		this.driver = driver;
	}
	
	public async ReturnReason overwrite(MatrixRenderer[]? matrix, DotsRenderer[]? dots, BacklightRenderer[]? backlight, Cancellable? cancellable = null ) {
		debug("Set overwrite renderer");
		
		SourceFunc? callback = null;
		lock(this.overwrite_matrix) {
			if(this.overwrite_callback != null) {
				callback = (owned) this.overwrite_callback;
			}
			
			this.overwrite_matrix = matrix;
			this.overwrite_dots = dots;
			this.overwrite_backlight = backlight;
			this.overwrite_callback = this.overwrite.callback;
			this.overwrite_cancellable = cancellable;
		}
		
		if(callback != null) {
			callback();
		}
		
		yield;
		
		if(cancellable.is_cancelled()) {
			debug("Unset overwrite renderer: CANCELLED");
			return ReturnReason.CANCELLED;
		}else if(this.overwrite_matrix == null && this.overwrite_dots == null && this.overwrite_backlight == null) {
			debug("Unset overwrite renderer: TERMINATED");
			return ReturnReason.TERMINATED;
		}else{
			debug("Unset overwrite renderer: REPLACED");
			return ReturnReason.REPLACED;
		}
	}
	
	public bool overwrite_active() {
		return this.overwrite_matrix != null || this.overwrite_dots != null || this.overwrite_backlight != null;
	}
	
	private bool reset_overwrite() {
		lock(this.overwrite_matrix) {
			if(!this.overwrite_active()) return false;
			
			SourceFunc? callback = null;
			if(this.overwrite_callback != null) {
				callback = (owned) this.overwrite_callback;
			}else{
				critical("Reset overwrite without callback");
			}
			
			this.overwrite_matrix = null;
			this.overwrite_dots = null;
			this.overwrite_backlight = null;
			this.overwrite_callback = null;
			this.overwrite_cancellable = null;
			
			if(callback != null) {
				Idle.add(() => {
					callback();
					return Source.REMOVE;
				});
			}
			
			return true;
		}
	}
	
	public uint8[] dump_colors() {
		uint8[] ret = new uint8[(this.matrix.length[0] * this.matrix.length[1] + this.dots.length + this.backlight.length) * 3];
		
		uint8 r,g,b;
		int i=0;
		for(int y=0;y<this.matrix.length[1];y++) {
			for(int x=0;x<this.matrix.length[0];x++) {
				this.matrix[x,y].get_rgb(out r, out g, out b, false);
				ret[i++] = r;
				ret[i++] = g;
				ret[i++] = b;
			}
		}
		for(int x=0;x<this.dots.length;x++) {
			this.dots[x].get_rgb(out r, out g, out b, false);
			ret[i++] = r;
			ret[i++] = g;
			ret[i++] = b;
		}
		for(int x=0;x<this.backlight.length;x++) {
			this.backlight[x].get_rgb(out r, out g, out b, false);
			ret[i++] = r;
			ret[i++] = g;
			ret[i++] = b;
		}
		
		return ret;
	}
	
	/*
	public void update_fps() {
		ClockConfiguration config = this.configurations[this.active];
		if(config == null) return;
		MatrixRenderer matrix = this.renderers[config.matrix] as MatrixRenderer;
		DotsRenderer dots = this.renderers[config.dots] as DotsRenderer;
		BacklightRenderer backlight = this.renderers[config.backlight] as BacklightRenderer;
		
		uint8 min = 2;
		uint8 max = uint8.MAX;
		
		uint8[] range;
		if(matrix != null) {
			range = matrix.get_fps_range();
			min = uint8.max( min, range[0] );
			max = uint8.min( max, range[1] );
		}
		
		if(dots != null) {
			range = dots.get_fps_range();
			min = uint8.max( min, range[0] );
			max = uint8.min( max, range[1] );
		}
		
		if(backlight != null) {
			range = backlight.get_fps_range();
			min = uint8.max( min, range[0] );
			max = uint8.min( max, range[1] );
		}
		
		if(min > max) critical("min FPS > max FPS");
		
		driver.set_fps(min);
	}
	*/
	
	public static void clear_leds_matrix( Color[,] leds_matrix ) {
		for(int i=0;i<leds_matrix.length[0];i++) {
			for(int j=0;j<leds_matrix.length[1];j++) {
				leds_matrix[i,j].set_hsv(0,0,0);
			}
		}
	}
	
	public void set_leds( Color[,] leds ) {
		this.matrix = wiring.get_matrix( leds );
		this.dots = wiring.get_dots( leds );
		this.backlight = wiring.get_backlight( leds );
	}
	
	public void render( ) {
		ClockConfiguration config = this.configurations[this.active];
		if(config == null) return;
		
		if(this.matrix == null || this.dots == null || this.backlight == null) return;
		
		MatrixRenderer[]? overwrite_matrix;
		DotsRenderer[]? overwrite_dots;
		BacklightRenderer[]? overwrite_backlight;
		Cancellable? overwrite_cancellable;
		
		lock(this.overwrite_matrix) {
			overwrite_matrix = this.overwrite_matrix;
			overwrite_dots = this.overwrite_dots;
			overwrite_backlight = this.overwrite_backlight;
			overwrite_cancellable = this.overwrite_cancellable;
		}
		
		bool ret = true;
		
		if(overwrite_matrix != null) {
			foreach( MatrixRenderer matrix in overwrite_matrix ) {
				if(matrix != null) ret = matrix.render_matrix( this.matrix ) && ret;
			}
		}else if(config != null) {
			foreach( JsonableString name in config.matrix ) {
				MatrixRenderer matrix = this.renderers[name.to_string()] as MatrixRenderer;
				if(matrix != null) ret = matrix.render_matrix( this.matrix ) && ret;
			}
		}
		
		if(overwrite_dots != null) {
			foreach( DotsRenderer dots in overwrite_dots ) {
				if(dots != null) ret = dots.render_dots( this.dots ) && ret;
			}
		}else if(config != null) {
			foreach( JsonableString name in config.dots ) {
				DotsRenderer dots = this.renderers[name.to_string()] as DotsRenderer;
				if(dots != null) ret = dots.render_dots( this.dots ) && ret;
			}
		}
		
		if(overwrite_backlight != null) {
			foreach( BacklightRenderer backlight in overwrite_backlight ) {
				if(backlight != null) ret = backlight.render_backlight( this.backlight ) && ret;
			}
		}else if(config != null) {
			foreach( JsonableString name in config.backlight ) {
				BacklightRenderer backlight = this.renderers[name.to_string()] as BacklightRenderer;
				if(backlight != null) ret = backlight.render_backlight( this.backlight ) && ret;
			}
		}
		
		if(!ret || overwrite_cancellable != null && overwrite_cancellable.is_cancelled()) {
			if(!this.reset_overwrite()) {
				this.active = "";
			}
		}
	}
}
