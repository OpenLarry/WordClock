using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Settings : GLib.Object, Jsonable {
	public string path;
	
	public JsonableTreeMap<Jsonable> objects { get; set; default = new JsonableTreeMap<Jsonable>(); }
	
	public Settings( string path ) {
		this.path = path;
	}
	
	public void load( ) throws Error {
		JsonHelper.load( this, path );
	}
	
	public void save() throws Error {
		JsonHelper.save( this, path, true );
	}
	
	public string get_string( string? jsonpath = null, bool pretty = false ) throws Error {
		return JsonHelper.get_string( this, jsonpath, pretty );
	}
	
	public void set_string( string data, string? jsonpath = null ) throws Error {
		JsonHelper.set_string( this, data, jsonpath );
	}
	
	public Json.Node get_json( string? jsonpath = null, bool pretty = false ) throws Error {
		return JsonHelper.get_json( this, jsonpath );
	}
	
	public void set_json( Json.Node data, string? jsonpath = null ) throws Error {
		JsonHelper.set_json( this, data, jsonpath );
	}
}
