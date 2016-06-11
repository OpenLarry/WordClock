using WordClock, Lua;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.LuaRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer, BacklightRenderer, DotsRenderer {
	public static Lua lua;
	
	private static Color[,] matrix;
	private static Color[] backlight;
	private static Color[] dots;
	
	public string matrix_function { get; set; default = ""; }
	public string backlight_function { get; set; default = ""; }
	public string dots_function { get; set; default = ""; }
	
	public static void init( Lua lua ) {
		LuaRenderer.lua = lua;
		
		lua.init.connect(() => {
			lua.register_func("set_matrix_led_rgb", set_matrix_led_rgb);
			lua.register_func("set_backlight_led_rgb", set_backlight_led_rgb);
			lua.register_func("set_dots_led_rgb", set_dots_led_rgb);
			lua.register_func("set_matrix_led_hsv", set_matrix_led_hsv);
			lua.register_func("set_backlight_led_hsv", set_backlight_led_hsv);
			lua.register_func("set_dots_led_hsv", set_dots_led_hsv);
		});
	}
	
	public bool render_matrix( Color[,] matrix ) {
		LuaRenderer.matrix = matrix;
		
		try {
			lua.call_function(this.matrix_function, { matrix.length[0], matrix.length[1] });
		} catch( LuaError e ) {
			stderr.printf("Lua error: %s\n", e.message);
		}
		
		return true;
	}
	
	public bool render_backlight( Color[] backlight ) {
		LuaRenderer.backlight = backlight;
		try {
			lua.call_function(this.backlight_function, { backlight.length });
		} catch( LuaError e ) {
			stderr.printf("Lua error: %s\n", e.message);
		}
		
		return true;
	}
	
	public bool render_dots( Color[] dots ) {
		LuaRenderer.dots = dots;
		try {
			lua.call_function(this.dots_function, { dots.length });
		} catch( LuaError e ) {
			stderr.printf("Lua error: %s\n", e.message);
		}
		
		return true;
	}
	
	public static int set_matrix_led_rgb( LuaVM vm ) {
		int x = vm.to_integer(1);
		int y = vm.to_integer(2);
		int r = vm.to_integer(3);
		int g = vm.to_integer(4);
		int b = vm.to_integer(5);
		int a = vm.is_number(6) ? vm.to_integer(6) : 255;
		
		if(a == 255) {
			matrix[x,y].set_rgb((uint8) r,(uint8) g,(uint8) b);
		}else{
			matrix[x,y].mix_with( new Color.from_rgb((uint8) r,(uint8) g,(uint8) b), (uint8) a );
		}
		
		
		return 0;
	}
	
	public static int set_backlight_led_rgb( LuaVM vm ) {
		int x = vm.to_integer(1);
		int r = vm.to_integer(2);
		int g = vm.to_integer(3);
		int b = vm.to_integer(4);
		int a = vm.is_number(5) ? vm.to_integer(5) : 255;
		
		if(a == 255) {
			backlight[x].set_rgb((uint8) r,(uint8) g,(uint8) b);
		}else{
			backlight[x].mix_with( new Color.from_rgb((uint8) r,(uint8) g,(uint8) b), (uint8) a );
		}
		
		return 0;
	}
	
	public static int set_dots_led_rgb( LuaVM vm ) {
		int x = vm.to_integer(1);
		int r = vm.to_integer(2);
		int g = vm.to_integer(3);
		int b = vm.to_integer(4);
		int a = vm.is_number(5) ? vm.to_integer(5) : 255;
		
		if(a == 255) {
			dots[x].set_rgb((uint8) r,(uint8) g,(uint8) b);
		}else{
			dots[x].mix_with( new Color.from_rgb((uint8) r,(uint8) g,(uint8) b), (uint8) a );
		}
		
		return 0;
	}
	
	public static int set_matrix_led_hsv( LuaVM vm ) {
		int x = vm.to_integer(1);
		int y = vm.to_integer(2);
		int h = vm.to_integer(3);
		int s = vm.to_integer(4);
		int v = vm.to_integer(5);
		int a = vm.is_number(6) ? vm.to_integer(6) : 255;
		
		if(a == 255) {
			matrix[x,y].set_hsv((uint16) h,(uint8) s,(uint8) v);
		}else{
			matrix[x,y].mix_with( new Color.from_hsv((uint16) h,(uint8) s,(uint8) v), (uint8) a );
		}
		
		return 0;
	}
	
	public static int set_backlight_led_hsv( LuaVM vm ) {
		int x = vm.to_integer(1);
		int h = vm.to_integer(2);
		int s = vm.to_integer(3);
		int v = vm.to_integer(4);
		int a = vm.is_number(5) ? vm.to_integer(5) : 255;
		
		if(a == 255) {
			backlight[x].set_hsv((uint16) h,(uint8) s,(uint8) v);
		}else{
			backlight[x].mix_with( new Color.from_hsv((uint16) h,(uint8) s,(uint8) v), (uint8) a );
		}
		
		return 0;
	}
	
	public static int set_dots_led_hsv( LuaVM vm ) {
		int x = vm.to_integer(1);
		int h = vm.to_integer(2);
		int s = vm.to_integer(3);
		int v = vm.to_integer(4);
		int a = vm.is_number(5) ? vm.to_integer(5) : 255;
		
		if(a == 255) {
			dots[x].set_hsv((uint16) h,(uint8) s,(uint8) v);
		}else{
			dots[x].mix_with( new Color.from_hsv((uint16) h,(uint8) s,(uint8) v), (uint8) a );
		}
		
		return 0;
	}
}
