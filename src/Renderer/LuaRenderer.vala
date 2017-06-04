using WordClock, Lua;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.LuaRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer, BacklightRenderer, DotsRenderer {
	public static Lua lua;
	
	private static Color[,]? matrix = null;
	private static Color[]? backlight = null;
	private static Color[]? dots = null;
	
	public string matrix_function { get; set; default = ""; }
	public string backlight_function { get; set; default = ""; }
	public string dots_function { get; set; default = ""; }
	
	public enum RendererType {
		MATRIX,
		BACKLIGHT,
		DOTS
	}
	public enum ColorModel {
		RGB,
		HSV
	}
	public enum Operation {
		SET,
		GET
	}
	
	public static void init( Lua lua ) {
		LuaRenderer.lua = lua;
		
		lua.init.connect(() => {
			lua.register_func("set_matrix_led_rgb", (v) => {return led_operation(v,RendererType.MATRIX,ColorModel.RGB,Operation.SET);});
			lua.register_func("set_backlight_led_rgb", (v) => {return led_operation(v,RendererType.BACKLIGHT,ColorModel.RGB,Operation.SET);});
			lua.register_func("set_dots_led_rgb", (v) => {return led_operation(v,RendererType.DOTS,ColorModel.RGB,Operation.SET);});
			lua.register_func("set_matrix_led_hsv", (v) => {return led_operation(v,RendererType.MATRIX,ColorModel.HSV,Operation.SET);});
			lua.register_func("set_backlight_led_hsv", (v) => {return led_operation(v,RendererType.BACKLIGHT,ColorModel.HSV,Operation.SET);});
			lua.register_func("set_dots_led_hsv", (v) => {return led_operation(v,RendererType.DOTS,ColorModel.HSV,Operation.SET);});
			
			lua.register_func("get_matrix_led_rgb", (v) => {return led_operation(v,RendererType.MATRIX,ColorModel.RGB,Operation.GET);});
			lua.register_func("get_backlight_led_rgb", (v) => {return led_operation(v,RendererType.BACKLIGHT,ColorModel.RGB,Operation.GET);});
			lua.register_func("get_dots_led_rgb", (v) => {return led_operation(v,RendererType.DOTS,ColorModel.RGB,Operation.GET);});
			lua.register_func("get_matrix_led_hsv", (v) => {return led_operation(v,RendererType.MATRIX,ColorModel.HSV,Operation.GET);});
			lua.register_func("get_backlight_led_hsv", (v) => {return led_operation(v,RendererType.BACKLIGHT,ColorModel.HSV,Operation.GET);});
			lua.register_func("get_dots_led_hsv", (v) => {return led_operation(v,RendererType.DOTS,ColorModel.HSV,Operation.GET);});
		});
	}
	
	public bool render_matrix( Color[,] matrix ) {
		LuaRenderer.matrix = matrix;
		try {
			lua.call_function(this.matrix_function, { matrix.length[0], matrix.length[1] });
		} catch( LuaError e ) {
			warning("Lua error: %s", e.message);
		}
		
		LuaRenderer.matrix = null;
		
		return true;
	}
	
	public bool render_backlight( Color[] backlight ) {
		LuaRenderer.backlight = backlight;
		try {
			lua.call_function(this.backlight_function, { backlight.length });
		} catch( LuaError e ) {
			warning("Lua error: %s", e.message);
		}
		LuaRenderer.backlight = null;
		
		return true;
	}
	
	public bool render_dots( Color[] dots ) {
		LuaRenderer.dots = dots;
		try {
			lua.call_function(this.dots_function, { dots.length });
		} catch( LuaError e ) {
			warning("Lua error: %s", e.message);
		}
		LuaRenderer.dots = null;
		
		return true;
	}
	
	public static int led_operation( LuaVM vm, RendererType type, ColorModel model, Operation op ) {
		int x=0,y=0,rh=0,gs=0,bv=0,a=0;
		
		x = vm.to_integer(1);
		if(type == RendererType.MATRIX) {
			y = vm.to_integer(2);
			if(op == Operation.SET) {
				rh = vm.to_integer(3);
				gs = vm.to_integer(4);
				bv = vm.to_integer(5);
				a = vm.is_number(6) ? vm.to_integer(6) : 255;
			}
		}else{
			if(op == Operation.SET) {
				rh = vm.to_integer(2);
				gs = vm.to_integer(3);
				bv = vm.to_integer(4);
				a = vm.is_number(5) ? vm.to_integer(5) : 255;
			}
		}
		
		Color color;
		switch(type) {
			case RendererType.MATRIX:
				if(matrix == null) return fail_null();
				color = matrix[x,y];
			break;
			case RendererType.BACKLIGHT:
				if(backlight == null) return fail_null();
				color = backlight[x];
			break;
			case RendererType.DOTS:
				if(dots == null) return fail_null();
				color = dots[x];
			break;
			default: // can not happen, but compiler fails otherwise
				color = null;
			break;
		}
		
		if(op == Operation.SET) {
			switch(model) {
				case ColorModel.RGB:
					if(a == 255) {
						color.set_rgb((uint8) rh,(uint8) gs,(uint8) bv);
					}else{
						color.mix_with( new Color.from_rgb((uint8) rh,(uint8) gs,(uint8) bv), (uint8) a );
					}
				break;
				case ColorModel.HSV:
					if(a == 255) {
						color.set_hsv((uint16) rh,(uint8) gs,(uint8) bv);
					}else{
						color.mix_with( new Color.from_hsv((uint16) rh,(uint8) gs,(uint8) bv), (uint8) a );
					}
				break;
			}
			
			return 0;
		}else{
			switch(model) {
				case ColorModel.RGB:
					uint8[] rgb = color.get_rgb();
					
					Value val = Value(typeof(uint));
					val.set_uint(rgb[0]);
					lua.push_value(val);
					val.set_uint(rgb[1]);
					lua.push_value(val);
					val.set_uint(rgb[2]);
					lua.push_value(val);
				break;
				case ColorModel.HSV:
					uint16[] hsv = color.get_hsv();
					
					Value val = Value(typeof(uint));
					val.set_uint(hsv[0]);
					lua.push_value(val);
					val.set_uint(hsv[1]);
					lua.push_value(val);
					val.set_uint(hsv[2]);
					lua.push_value(val);
				break;
			}
			
			return 3;
		}
	}
	
	public static int fail_null() {
		lua.log_message("Illegal led setting/getting outside render function!");
		warning("Illegal led setting/getting outside render function");
		return 0;
	}
}
