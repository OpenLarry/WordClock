using WordClock, Lua, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.LuaSettings : GLib.Object {
	private static Lua lua;
	private static Settings settings;
	
	public static void init(Lua lua, Settings settings) {
		LuaSettings.settings = settings;
		LuaSettings.lua = lua;
		
		lua.init.connect(() => {
			lua.register_func("get_settings", get_settings);
			lua.register_func("set_settings", set_settings);
		});
	}
	
	private static int get_settings(LuaVM vm) {
		string path = vm.to_string(1);
		if(path == null) path = "";
		
		Value val;
		try {
			string json = JsonHelper.to_string(settings.to_json(path));
			
			val = Value(typeof(string));
			val.set_string(json);
		} catch( Error e ) {
			stderr.printf("Error: %s\n", e.message);
			lua.log_message("Error: "+e.message);
			
			val = Value(typeof(bool));
			val.set_boolean(true);
		}
		
		lua.push_value(val);
		
		return 1;
	}
	
	private static int set_settings(LuaVM vm) {
		string json = vm.to_string(1);
		string path = vm.to_string(2);
		if(path == null) path = "";
		
		Value val = Value(typeof(bool));
		
		try {
			settings.from_json( JsonHelper.from_string( json ), path );
			settings.deferred_save();
			
			val.set_boolean(true);
		} catch( Error e ) {
			stderr.printf("Error: %s\n", e.message);
			lua.log_message("Error: "+e.message);
			
			val.set_boolean(false);
		}
		
		lua.push_value(val);
		
		return 1;
	}
}
