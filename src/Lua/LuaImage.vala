using WordClock, Lua, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.LuaImage : GLib.Object {
	private static Lua lua;
	private static ImageOverlay image_overlay;
	private static TreeMap<uint, Cancellable> cancellable_map;
	private static uint cancellable_id = 0;
	
	public static void init(Lua lua, ImageOverlay image_overlay) {
		LuaImage.image_overlay = image_overlay;
		LuaImage.lua = lua;
		cancellable_map = new TreeMap<uint, Cancellable>();
		
		lua.init.connect(() => {
			lua.register_func("image", image);
			lua.register_func("stop_image", stop_image);
		});
	}
	
	private static int image(LuaVM vm) {
		string path = vm.to_string(1);
		int x_speed = vm.to_integer(2);
		int y_speed = vm.to_integer(3);
		int count = vm.to_integer(4);
		if(count == 0) count = 1;
		
		Value val = Value(typeof(uint));
		cancellable_map[++cancellable_id] = new Cancellable();
		uint id = cancellable_id;
		image_overlay.image.begin(path, x_speed, y_speed, count, cancellable_map[cancellable_id], (obj,res) => {
			cancellable_map.unset(id);
		});
		val.set_uint(cancellable_id);
		
		lua.push_value(val);
		
		return 1;
	}
	
	private static int stop_image(LuaVM vm) {
		int id = vm.to_integer(1);
		
		Value val = Value(typeof(bool));
		if(cancellable_map[id] != null) {
			cancellable_map[id].cancel();
			
			val.set_boolean(true);
		}else{
			val.set_boolean(false);
		}
		
		lua.push_value(val);
		
		return 1;
	}
}
