using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Settings : GLib.Object, Jsonable {
	private uint timeout = 0;
	public string path;
	
	public uint save_time { get; set; default = 5000; }
	public JsonableTreeMap<Jsonable> objects { get; set; default = new JsonableTreeMap<Jsonable>(); }
	
	public Settings( string path ) {
		this.path = path;
	}
	
	public void load( ) throws Error {
		JsonHelper.load( this, path );
	}
	
	public void save() throws Error {
		if(this.timeout > 0) GLib.Source.remove(this.timeout);
		JsonHelper.save( this, path, true );
	}
	
	public void deferred_save() throws Error {
		if(this.timeout > 0) GLib.Source.remove(this.timeout);
		this.timeout = GLib.Timeout.add(this.save_time, () => {
			try{
				this.save();
			}catch( Error e ) {
				stderr.printf("Error: %s\n", e.message);
			}
			return false;
		});
	}
	
	public string get_string( string? jsonpath = null, bool pretty = false ) throws Error {
		return JsonHelper.get_string( this, jsonpath, pretty );
	}
	
	public void set_string( string data, string? jsonpath = null ) throws Error {
		JsonHelper.set_string( this, data, jsonpath );
		this.deferred_save();
	}
	
	public Json.Node get_json( string? jsonpath = null, bool pretty = false ) throws Error {
		return JsonHelper.get_json( this, jsonpath );
	}
	
	public void set_json( Json.Node data, string? jsonpath = null ) throws Error {
		JsonHelper.set_json( this, data, jsonpath );
		this.deferred_save();
	}
}
