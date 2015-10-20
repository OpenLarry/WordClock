using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.ClockRenderer : GLib.Object, FrameRenderer {
	private LedDriver driver;
	private ClockWiring wiring;
	
	private MatrixRenderer matrix;
	private DotsRenderer dots;
	private BacklightRenderer backlight;
	
	private TreeMap<string, MatrixRenderer> matrix_renderers = new TreeMap<string, MatrixRenderer>();
	private TreeMap<string, DotsRenderer> dots_renderers = new TreeMap<string, DotsRenderer>();
	private TreeMap<string, BacklightRenderer> backlight_renderers = new TreeMap<string, BacklightRenderer>();
	
	public ClockRenderer( ClockWiring wiring, LedDriver driver ) {
		this.wiring = wiring;
		this.driver = driver;
	}
	
	public void add_matrix_renderer( string name, MatrixRenderer renderer ) {
		this.matrix_renderers.set( name, renderer );
	}
	
	public void add_dots_renderer( string name, DotsRenderer renderer ) {
		this.dots_renderers.set( name, renderer );
	}
	
	public void add_backlight_renderer( string name, BacklightRenderer renderer ) {
		this.backlight_renderers.set( name, renderer );
	}
	
	public MatrixRenderer get_matrix_renderer( string name ) {
		return this.matrix_renderers.get( name );
	}
	
	public bool activate( string? matrix_name, string? dots_name, string? backlight_name ) {
		var ret = true;
		
		uint8 min = 2;
		uint8 max = uint8.MAX;
		
		if(this.matrix_renderers.has_key( matrix_name )) {
			var matrix = this.matrix_renderers.get( matrix_name );
			matrix.activate();
			this.matrix = matrix;
		}else{
			ret = false;
		}
		
		if(this.dots_renderers.has_key( dots_name )) {
			var dots = this.dots_renderers.get( dots_name );
			dots.activate();
			this.dots = dots;
		}else{
			ret = false;
		}
		
		if(this.backlight_renderers.has_key( backlight_name )) {
			var backlight = this.backlight_renderers.get( backlight_name );
			backlight.activate();
			this.backlight = backlight;
		}else{
			ret = false;
		}
		
		uint8[] range = this.matrix.get_fps_range();
		min = uint8.max( min, range[0] );
		max = uint8.min( max, range[1] );
		
		range = this.dots.get_fps_range();
		min = uint8.max( min, range[0] );
		max = uint8.min( max, range[1] );
		
		range = this.backlight.get_fps_range();
		min = uint8.max( min, range[0] );
		max = uint8.min( max, range[1] );
		
		if(min > max) stderr.printf("min FPS > max FPS !\n");
		
		driver.set_fps(min);
		
		return ret;
	}
	
	public static void clear_leds_matrix( Color[,] leds_matrix ) {
		for(int i=0;i<leds_matrix.length[0];i++) {
			for(int j=0;j<leds_matrix.length[1];j++) {
				leds_matrix[i,j].r = 0;
				leds_matrix[i,j].g = 0;
				leds_matrix[i,j].b = 0;
			}
		}
	}
	
	public static void clear_leds( Color[] leds ) {
		for(int i=0;i<leds.length;i++) {
			leds[i].r = 0;
			leds[i].g = 0;
			leds[i].b = 0;
		}
	}
	
	public bool render( Color[,] leds ) {
		return matrix.render_matrix( wiring.get_matrix( leds ) ) && dots.render_dots( wiring.get_dots( leds ) ) && backlight.render_backlight( wiring.get_backlight( leds ) );
	}
}
