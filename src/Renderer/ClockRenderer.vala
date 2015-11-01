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
	
	public ClockRenderer( ClockWiring wiring, LedDriver driver ) {
		this.wiring = wiring;
		this.driver = driver;
		
		this.notify["active"].connect(this.update_fps);
	}
	
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
		ClockConfiguration config = this.configurations[this.active];
		if(config == null) return true;
		
		MatrixRenderer matrix = this.renderers[config.matrix] as MatrixRenderer;
		DotsRenderer dots = this.renderers[config.dots] as DotsRenderer;
		BacklightRenderer backlight = this.renderers[config.backlight] as BacklightRenderer;
		
		bool ret = true;
		if(matrix != null) ret = matrix.render_matrix( wiring.get_matrix( leds ) ) && ret;
		if(dots != null) ret = dots.render_dots( wiring.get_dots( leds ) ) && ret;
		if(backlight != null) ret = backlight.render_backlight( wiring.get_backlight( leds ) ) && ret;
		
		return ret;
	}
}
