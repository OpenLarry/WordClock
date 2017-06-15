using WordClock, Lua, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.LuaMessage : GLib.Object {
	private static Lua lua;
	private static MessageOverlay message_overlay;
	private static TreeMap<uint, Cancellable> cancellable_map;
	private static uint cancellable_id = 0;
	
	public static void init(Lua lua, MessageOverlay message_overlay) {
		LuaMessage.message_overlay = message_overlay;
		LuaMessage.lua = lua;
		cancellable_map = new TreeMap<uint, Cancellable>();
		
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
		cancellable_map[++cancellable_id] = new Cancellable();
		uint id = cancellable_id;
		message_overlay.message.begin(text, type, count, cancellable_map[cancellable_id], (obj,res) => {
			cancellable_map.unset(id);
		});
		val.set_uint(cancellable_id);
		
		lua.push_value(val);
		
		return 1;
	}
	
	private static int stop_message(LuaVM vm) {
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
