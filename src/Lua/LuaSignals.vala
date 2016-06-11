using WordClock, Lua, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.LuaSignals : GLib.Object {
	private static Lua lua;
	private static SignalRouter signal_router;
	
	private static TreeMap<uint,string> lua_funcs;
	
	public static void init(Lua lua, SignalRouter signal_router) {
		LuaSignals.signal_router = signal_router;
		LuaSignals.lua = lua;
		
		lua.init.connect(() => {
			LuaSignals.lua_funcs = new TreeMap<uint,string>();
			lua.register_func("register_signal", register_signal);
			lua.register_func("unregister_signal", unregister_signal);
		});
		
		lua.deinit.connect(() => {
			if(lua_funcs != null) {
				foreach(uint id in lua_funcs.keys) {
					signal_router.remove_signal_func(id);
				}
				lua_funcs.clear();
			}
		});
	}
	
	private static int register_signal(LuaVM vm) {
		string pattern = vm.to_string(1);
		string function = vm.to_string(2);
		bool before = vm.to_boolean(3);
		
		Value val = Value(typeof(int));
		
		try {
			uint id = signal_router.add_signal_func(new Regex(pattern), handle_signal, before);
			lua_funcs[id] = function;
			
			val.set_int((int) id);
		} catch ( RegexError e ) {
			stderr.printf("Regex Error: %s\n", e.message);
			lua.log_message("Regex Error: "+e.message);
			
			val.set_int(-1);
		}
		
		lua.push_value(val);
		
		return 1;
	}
	
	private static int unregister_signal(LuaVM vm) {
		int id = vm.to_integer(1);
		
		Value val = Value(typeof(bool));
		val.set_boolean(signal_router.remove_signal_func(id));
		lua_funcs.unset(id);
		
		lua.push_value(val);
		
		return 1;
	}
	
	private static bool handle_signal(uint id, string signal_name) {
		string func = lua_funcs[id];
		Value[] ret = {Value(typeof(bool))};
		
		if(func == null) {
			stderr.puts("Function to Regex not found!\n"); // should not happen
		}else{
			try {
				lua.call_function( func, { signal_name }, ret );
			} catch( LuaError e ) {
				stderr.printf("Lua error: %s\n", e.message);
			}
		}
		
		return (bool) ret[0];
	}
}
