using WordClock, Lua, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.LuaHwinfo : GLib.Object {
	private static Lua lua;
	private static HardwareInfo hwinfo;
	
	public static void init(Lua lua, HardwareInfo hwinfo) {
		LuaHwinfo.hwinfo = hwinfo;
		LuaHwinfo.lua = lua;
		
		lua.init.connect(() => {
			lua.register_func("get_hwinfo", get_hwinfo);
		});
	}
	
	private static int get_hwinfo(LuaVM vm) {
		string path = vm.to_string(1);
		if(path == null) path = "";
		
		Value val;
		try {
			string json = JsonHelper.to_string(hwinfo.to_json(path));
			
			val = Value(typeof(string));
			val.set_string(json);
		} catch( Error e ) {
			warning(e.message);
			lua.log_message("Error: "+e.message);
			
			val = Value(typeof(bool));
			val.set_boolean(false);
		}
		
		lua.push_value(val);
		
		return 1;
	}
}
