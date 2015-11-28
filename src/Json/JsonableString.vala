using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 *
 * Container class
 */
public class WordClock.JsonableString : GLib.Object, Jsonable {
	public string string { get; set; default = ""; }
	
	public JsonableString( string s = "") {
		this.string = s;
	}
	
	public string to_string() {
		return this.string;
	}
	
	public Json.Node to_json( string path = "" ) throws JsonError {
		Value val = Value( typeof(string) );
		val.set_string( string );
		return JsonHelper.value_to_json( val, path );
	}
	
	public void from_json(Json.Node node, string path = "") throws JsonError {
		Value val = Value( typeof(string) );
		JsonHelper.value_from_json( node, ref val, path );
		this.string = val.dup_string();
	}
}
