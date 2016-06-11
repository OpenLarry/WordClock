using WordClock, Lua, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.LuaBuzzer: GLib.Object {
	private static Lua lua;
	
	public static void init(Lua lua) {
		LuaBuzzer.lua = lua;
		
		lua.init.connect(() => {
			lua.register_func("beep", beep);
		});
	}
	
	private static int beep(LuaVM vm) {
		int msec = vm.to_integer(1);
		int freq = vm.to_integer(2);
		int volume = vm.to_integer(3);
		
		if(msec <= 0) msec = 250;
		if(freq <= 0) freq = 2000;
		if(volume <= 0) volume = 255;
		
		Buzzer.beep((uint16) msec, (uint16) freq, (uint8) volume);
		
		return 0;
	}
}
