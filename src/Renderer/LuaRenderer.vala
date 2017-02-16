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
			
			lua.register_func("get_matrix_led_rgb", get_matrix_led_rgb);
			lua.register_func("get_backlight_led_rgb", get_backlight_led_rgb);
			lua.register_func("get_dots_led_rgb", get_dots_led_rgb);
			lua.register_func("get_matrix_led_hsv", get_matrix_led_hsv);
			lua.register_func("get_backlight_led_hsv", get_backlight_led_hsv);
			lua.register_func("get_dots_led_hsv", get_dots_led_hsv);
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
		int x,y,r,g,b,a;
		pop_color_value(vm, true, out x, out y, out r, out g, out b, out a);
		
		if(a == 255) {
			matrix[x,y].set_rgb((uint8) r,(uint8) g,(uint8) b);
		}else{
			matrix[x,y].mix_with( new Color.from_rgb((uint8) r,(uint8) g,(uint8) b), (uint8) a );
		}
		
		
		return 0;
	}
	
	public static int set_backlight_led_rgb( LuaVM vm ) {
		int x,r,g,b,a;
		pop_color_value(vm, false, out x, null, out r, out g, out b, out a);
		
		if(a == 255) {
			backlight[x].set_rgb((uint8) r,(uint8) g,(uint8) b);
		}else{
			backlight[x].mix_with( new Color.from_rgb((uint8) r,(uint8) g,(uint8) b), (uint8) a );
		}
		
		return 0;
	}
	
	public static int set_dots_led_rgb( LuaVM vm ) {
		int x,r,g,b,a;
		pop_color_value(vm, false, out x, null, out r, out g, out b, out a);
		
		if(a == 255) {
			dots[x].set_rgb((uint8) r,(uint8) g,(uint8) b);
		}else{
			dots[x].mix_with( new Color.from_rgb((uint8) r,(uint8) g,(uint8) b), (uint8) a );
		}
		
		return 0;
	}
	
	public static int set_matrix_led_hsv( LuaVM vm ) {
		int x,y,h,s,v,a;
		pop_color_value(vm, true, out x, out y, out h, out s, out v, out a);
		
		if(a == 255) {
			matrix[x,y].set_hsv((uint16) h,(uint8) s,(uint8) v);
		}else{
			matrix[x,y].mix_with( new Color.from_hsv((uint16) h,(uint8) s,(uint8) v), (uint8) a );
		}
		
		return 0;
	}
	
	public static int set_backlight_led_hsv( LuaVM vm ) {
		int x,h,s,v,a;
		pop_color_value(vm, false, out x, null, out h, out s, out v, out a);
		
		if(a == 255) {
			backlight[x].set_hsv((uint16) h,(uint8) s,(uint8) v);
		}else{
			backlight[x].mix_with( new Color.from_hsv((uint16) h,(uint8) s,(uint8) v), (uint8) a );
		}
		
		return 0;
	}
	
	public static int set_dots_led_hsv( LuaVM vm ) {
		int x,h,s,v,a;
		pop_color_value(vm, false, out x, null, out h, out s, out v, out a);
		
		if(a == 255) {
			dots[x].set_hsv((uint16) h,(uint8) s,(uint8) v);
		}else{
			dots[x].mix_with( new Color.from_hsv((uint16) h,(uint8) s,(uint8) v), (uint8) a );
		}
		
		return 0;
	}
	
	public static int get_matrix_led_rgb( LuaVM vm ) {
		int x = vm.to_integer(1);
		int y = vm.to_integer(2);
		
		push_rgb_value(matrix[x,y].get_rgb());
		
		return 3;
	}
	
	public static int get_backlight_led_rgb( LuaVM vm ) {
		int x = vm.to_integer(1);
		
		push_rgb_value(backlight[x].get_rgb());
		
		return 3;
	}
	
	public static int get_dots_led_rgb( LuaVM vm ) {
		int x = vm.to_integer(1);
		
		push_rgb_value(dots[x].get_rgb());
		
		return 3;
	}
	
	public static int get_matrix_led_hsv( LuaVM vm ) {
		int x = vm.to_integer(1);
		int y = vm.to_integer(2);
		
		push_hsv_value(matrix[x,y].get_hsv());
		
		return 3;
	}
	
	public static int get_backlight_led_hsv( LuaVM vm ) {
		int x = vm.to_integer(1);
		
		push_hsv_value(backlight[x].get_hsv());
		
		return 3;
	}
	
	public static int get_dots_led_hsv( LuaVM vm ) {
		int x = vm.to_integer(1);
		
		push_hsv_value(dots[x].get_hsv());
		
		return 3;
	}
	
	private static void pop_color_value( LuaVM vm, bool with_y, out int x, out int y, out int rh, out int gs, out int bv, out int a) {
		x = vm.to_integer(1);
		if(with_y) {
			y = vm.to_integer(2);
			rh = vm.to_integer(3);
			gs = vm.to_integer(4);
			bv = vm.to_integer(5);
			a = vm.is_number(6) ? vm.to_integer(6) : 255;
		}else{
			y = -1;
			rh = vm.to_integer(2);
			gs = vm.to_integer(3);
			bv = vm.to_integer(4);
			a = vm.is_number(5) ? vm.to_integer(5) : 255;
		}
	}
	
	private static void push_rgb_value( uint8[] rgb ) {
		Value val = Value(typeof(uint));
		val.set_uint(rgb[0]);
		lua.push_value(val);
		val.set_uint(rgb[1]);
		lua.push_value(val);
		val.set_uint(rgb[2]);
		lua.push_value(val);
	}
	
	private static void push_hsv_value( uint16[] rgb ) {
		Value val = Value(typeof(uint));
		val.set_uint(rgb[0]);
		lua.push_value(val);
		val.set_uint(rgb[1]);
		lua.push_value(val);
		val.set_uint(rgb[2]);
		lua.push_value(val);
	}
}
