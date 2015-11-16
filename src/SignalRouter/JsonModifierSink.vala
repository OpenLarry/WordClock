using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.JsonModifierSink : GLib.Object, Jsonable, SignalSink {
	public JsonableArrayList<JsonableNode> settings { get; set; default = new JsonableArrayList<JsonableNode>((a,b) => {
		if(a.node == null || b.node == null) return false;
		return JsonHelper.equals(a.node,b.node);
	}); }
	
	public string path { get; set; default = ""; }
	public bool cyclic { get; set; default = false; }
	
	public void action(int repetition) {
		try {
			Json.Node json = Main.settings.to_json( this.path );
			JsonableNode node = new JsonableNode(json);
			int index = this.settings.index_of(node);
			if(index >= 0) {
				index = (index+1);
			}else{
				index = 0;
			}
			
			if(index >= this.settings.size) {
				if(this.cyclic) {
					index = 0;
				}else{
					index = this.settings.size-1;
				}
			}
			
			Main.settings.from_json( this.settings[index].node.copy(), this.path );
			Main.settings.deferred_save();
		} catch( Error e ) {
			stderr.printf("Error: %s\n", e.message);
		}
	}
}
