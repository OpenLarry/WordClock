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
	
	public ClockRenderer( ClockWiring wiring, LedDriver driver ) {
		this.wiring = wiring;
		this.driver = driver;
	}
	
	public void set_overwrite( MatrixRenderer[]? matrix, DotsRenderer[]? dots, BacklightRenderer[]? backlight ) {
		lock(overwrite_matrix) {
			this.overwrite_matrix = matrix;
			this.overwrite_dots = dots;
			this.overwrite_backlight = backlight;
		}
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
		
		if(min > max) stderr.printf("min FPS > max FPS !\n");
		
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
	
	public static void clear_leds( Color[] leds ) {
		for(int i=0;i<leds.length;i++) {
			leds[i].set_hsv(0,0,0);
		}
	}
	
	public void render( Color[,] leds ) {
		ClockConfiguration config = this.configurations[this.active];
		if(config == null) return;
		
		MatrixRenderer[]? overwrite_matrix;
		DotsRenderer[]? overwrite_dots;
		BacklightRenderer[]? overwrite_backlight;
		
		lock(this.overwrite_matrix) {
			overwrite_matrix = this.overwrite_matrix;
			overwrite_dots = this.overwrite_dots;
			overwrite_backlight = this.overwrite_backlight;
		}
		
		bool ret = true;
		
		if(overwrite_matrix != null) {
			foreach( MatrixRenderer matrix in overwrite_matrix ) {
				if(matrix != null) ret = matrix.render_matrix( wiring.get_matrix( leds ) ) && ret;
			}
		}else if(config != null) {
			foreach( JsonableString name in config.matrix ) {
				MatrixRenderer matrix = this.renderers[name.to_string()] as MatrixRenderer;
				if(matrix != null) ret = matrix.render_matrix( wiring.get_matrix( leds ) ) && ret;
			}
		}
		
		if(overwrite_dots != null) {
			foreach( DotsRenderer dots in overwrite_dots ) {
				if(dots != null) ret = dots.render_dots( wiring.get_dots( leds ) ) && ret;
			}
		}else if(config != null) {
			foreach( JsonableString name in config.dots ) {
				DotsRenderer dots = this.renderers[name.to_string()] as DotsRenderer;
				if(dots != null) ret = dots.render_dots( wiring.get_dots( leds ) ) && ret;
			}
		}
		
		if(overwrite_backlight != null) {
			foreach( BacklightRenderer backlight in overwrite_backlight ) {
				if(backlight != null) ret = backlight.render_backlight( wiring.get_backlight( leds ) ) && ret;
			}
		}else if(config != null) {
			foreach( JsonableString name in config.backlight ) {
				BacklightRenderer backlight = this.renderers[name.to_string()] as BacklightRenderer;
				if(backlight != null) ret = backlight.render_backlight( wiring.get_backlight( leds ) ) && ret;
			}
		}
		
		if(!ret) {
			lock(this.overwrite_matrix) {
				if(overwrite_matrix != null || overwrite_dots != null || overwrite_backlight != null) {
					this.overwrite_matrix = null;
					this.overwrite_dots = null;
					this.overwrite_backlight = null;
				}else{
					this.active = "";
				}
			}
		}
	}
}
