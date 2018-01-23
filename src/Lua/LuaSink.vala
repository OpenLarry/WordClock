using WordClock, Lua, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.LuaSink : GLib.Object, Jsonable, SignalSink {
	public string function { get; set; default = ""; }
	public JsonableNode parameter { get; set; default = new JsonableNode(); }
	
	private static Lua lua;
	
	public static void init(Lua lua) {
		LuaSink.lua = lua;
	}
	
	public void action() {
		try{
			lua.call_function( this.function, { JsonHelper.to_string( this.parameter.to_json() ) } );
		}catch( Error e ) {
			warning("Lua error: %s", e.message);
			lua.log_message("Error: "+e.message);
		}
	}
}
