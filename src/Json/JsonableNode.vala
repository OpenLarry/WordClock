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
	
	public Json.Node to_json() {
		return node;
	}
	
	public void from_json(Json.Node node) {
		this.node = node;
	}
}
