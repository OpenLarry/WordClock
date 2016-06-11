using WordClock, Lua, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.LuaSink : GLib.Object, Jsonable, SignalSink {
	public string function { get; set; default = ""; }
	public JsonableArrayList<JsonableNode> parameter { get; set; default = new JsonableArrayList<JsonableNode>(); }
	
	private static Lua lua;
	
	public static void init(Lua lua) {
		LuaSink.lua = lua;
	}
	
	public void action() {
		try{
			lua.call_function( this.function, { JsonHelper.to_string( this.parameter.to_json() ) } );
		}catch( Error e ) {
			stderr.printf("Error: %s\n", e.message);
		}
	}
}
