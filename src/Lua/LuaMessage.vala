using WordClock, Lua, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.LuaMessage : GLib.Object {
	private static Lua lua;
	private static MessageOverlay message_overlay;
	
	public static void init(Lua lua, MessageOverlay message_overlay) {
		LuaMessage.message_overlay = message_overlay;
		LuaMessage.lua = lua;
		
		lua.init.connect(() => {
			lua.register_func("message", message);
			lua.register_func("stop_message", stop_message);
		});
	}
	
	private static int message(LuaVM vm) {
		string text = vm.to_string(1);
		int count = vm.to_integer(2);
		if(count == 0) count = 1;
		string message_type = vm.to_string(3);
		MessageType type;
		
		if(message_type == null) {
			type = MessageType.INFO;
		}else{
			type = MessageType.from_string(message_type);
		}
		
		
		Value val = Value(typeof(uint));
		val.set_uint(message_overlay.message(text, type, count));
		
		lua.push_value(val);
		
		return 1;
	}
	
	private static int stop_message(LuaVM vm) {
		int id = vm.to_integer(1);
		
		Value val = Value(typeof(bool));
		val.set_boolean(message_overlay.stop(id));
		
		lua.push_value(val);
		
		return 1;
	}
}
