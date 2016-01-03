using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.JsonModifierSink : GLib.Object, Jsonable, SignalSink {
	public JsonableArrayList<JsonableNode> settings { get; set; default = new JsonableArrayList<JsonableNode>((a,b) => {
		if(a.node == null || b.node == null) return false;
		return JsonHelper.intersection_equals(a.node,b.node);
	}); }
	
	public JsonableArrayList<JsonableString> paths { get; set; default = new JsonableArrayList<JsonableString>(); }
	public bool cyclic { get; set; default = false; }
	public bool synchronize { get; set; default = true; }
	
	public int last_index = -1;
	
	public void action() {
		int index = -1;
		
		foreach( JsonableString jsonpath in this.paths ) {
			string path = jsonpath.string;
			
			try {
				// try to use last index
				if((this.synchronize || this.paths.size == 1) && index < 0 && this.last_index >= 0 && this.last_index < this.settings.size) {
					Json.Node json = Main.settings.to_json( path );
					if(JsonHelper.intersection_equals(json, this.settings[this.last_index].node)) {
						index = this.next_index(this.last_index);
						
						this.last_index = index;
					}
				}
				
				// search current state in settings array
				if(!this.synchronize && this.paths.size > 1 || index < 0) {
					Json.Node json = Main.settings.to_json( path );
					JsonableNode node = new JsonableNode(json);
					
					index = this.next_index( this.settings.index_of(node) );
					
					this.last_index = index;
				}
				
				Main.settings.from_json( this.settings[index].node.copy(), path );
			} catch( Error e ) {
				stderr.printf("Error: %s\n", e.message);
			}
		}
		
		Main.settings.deferred_save();
	}
	
	protected int next_index( int index ) {
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
		
		return index;
	}
}
