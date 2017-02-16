using WordClock, Lua, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.LuaSignals : GLib.Object {
	private static Lua lua;
	private static SignalRouter signal_router;
	
	private static TreeMap<uint,string> lua_funcs;
	private static TreeMap<uint,int> lua_reffuncs;
	
	public static void init(Lua lua, SignalRouter signal_router) {
		LuaSignals.signal_router = signal_router;
		LuaSignals.lua = lua;
		
		lua.init.connect(() => {
			LuaSignals.lua_funcs = new TreeMap<uint,string>();
			LuaSignals.lua_reffuncs = new TreeMap<uint,int>();
			lua.register_func("register_signal", register_signal);
			lua.register_func("unregister_signal", unregister_signal);
			lua.register_func("trigger_signal", trigger_signal);
		});
		
		lua.deinit.connect(() => {
			if(lua_funcs != null) {
				foreach(uint id in lua_funcs.keys) {
					signal_router.remove_signal_func(id);
				}
				lua_funcs.clear();
			}
			if(lua_reffuncs != null) {
				foreach(uint id in lua_reffuncs.keys) {
					signal_router.remove_signal_func(id);
				}
				lua_reffuncs.clear();
			}
		});
	}
	
	private static int register_signal(LuaVM vm) {
		string pattern = vm.to_string(1);
		bool before = vm.to_boolean(3);
		
		if(vm.get_top() > 2) vm.pop(vm.get_top() - 2);
		
		string? function = vm.is_string(-1) ? vm.to_string(-1) : null;
		int reffunction = vm.is_function(-1) ? vm.reference(PseudoIndex.REGISTRY) : Reference.NIL;
		
		Value val = Value(typeof(int));
		
		if(function != null || reffunction != Reference.NIL) {
			try {
				uint id = signal_router.add_signal_func(new Regex(pattern), handle_signal, before);
				if(function != null) lua_funcs[id] = function;
				if(reffunction != Reference.NIL) lua_reffuncs[id] = reffunction;
				
				val.set_int((int) id);
			} catch ( RegexError e ) {
				stderr.printf("Regex Error: %s\n", e.message);
				lua.log_message("Regex Error: "+e.message);
				
				val.set_int(-1);
			}
		}else{
			stderr.printf("Invalid function!");
			lua.log_message("Invalid function!");
			
			val.set_int(-1);
		}
		
		lua.push_value(val);
		
		return 1;
	}
	
	private static int unregister_signal(LuaVM vm) {
		int id = vm.to_integer(1);
		
		Value val = Value(typeof(bool));
		val.set_boolean(signal_router.remove_signal_func(id));
		if(lua_funcs.has_key(id)) lua_funcs.unset(id);
		
		if(lua_reffuncs.has_key(id)) {
			vm.unreference(PseudoIndex.REGISTRY, lua_reffuncs[id]);
			lua_reffuncs.unset(id);
		}
		
		lua.push_value(val);
		
		return 1;
	}
	
	private static int trigger_signal(LuaVM vm) {
		string signal_name = vm.to_string(1);
		
		signal_router.trigger_signal(signal_name);
		
		return 0;
	}
	
	private static bool handle_signal(uint id, string signal_name) {
		Value[] ret = {Value(typeof(bool))};
		try {
			if(lua_funcs.has_key(id)) {
				lua.call_function( lua_funcs[id], { signal_name }, ret );
			}else if(lua_reffuncs.has_key(id)) {
				lua.call_reffunction( lua_reffuncs[id], { signal_name }, ret );
			}else{
				stderr.puts("Function to Regex not found!\n"); // should not happen
			}
		} catch( LuaError e ) {
			stderr.printf("Lua error: %s\n", e.message);
		}
		
		return (bool) ret[0];
	}
}
