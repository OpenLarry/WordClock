using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 *
 * Container class
 */
public class WordClock.JsonableNode : GLib.Object, Jsonable {
	public Json.Node node { get; set; }
	
	public JsonableNode( Json.Node node ) {
		this.node = node;
	}
	
	public Json.Node to_json( string path = "" ) throws JsonError {
		if(path!="") throw new JsonError.INVALID_PATH("Invalid path '%s'!".printf(path));
		
		return node;
	}
	
	public void from_json(Json.Node node, string path = "") throws JsonError {
		if(path!="") throw new JsonError.INVALID_PATH("Invalid path '%s'!".printf(path));
		
		this.node = node;
	}
}
