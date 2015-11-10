using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.JsonableTreeMultiMap<V> : Gee.TreeMultiMap<string,V>, Jsonable {
	public JsonableTreeMultiMap(owned CompareDataFunc<string>? key_compare_func = null, owned CompareDataFunc<V>? value_compare_func = null) {
		base((owned) key_compare_func, (owned) value_compare_func);
		
		if(!this.value_type.is_a(typeof(Jsonable))) stderr.puts("Value does not implement Jsonable interface!\n");
	}
	
	public Json.Node to_json() {
		if(!this.value_type.is_a(typeof(Jsonable))) return new Json.Node( Json.NodeType.NULL );
		
		Json.Object obj = new Json.Object();
		foreach( string entry_key in this.get_keys() ) {
			Json.Array arr = new Json.Array();
			foreach( V entry_val in this.get(entry_key) ) {
				Value val = Value( this.value_type );
				val.set_object( (Jsonable) entry_val );
				arr.add_element( value_to_json(val) );
			}
			obj.set_array_member(entry_key, arr);
		}
		
		Json.Node node = new Json.Node( Json.NodeType.OBJECT );
		node.take_object(obj);
		
		return node;
	}
	
	public void from_json(Json.Node node) throws JsonableError {
		if(!this.value_type.is_a(typeof(Jsonable))) throw new JsonableError.INVALID_CLASS_NAME("Class does not implement interface Jsonable!");
		if( node.get_node_type() != Json.NodeType.OBJECT ) throw new JsonableError.INVALID_NODE_TYPE("Invalid node type! Object expected.");
		
		// Can not use Json.Object.foreach_member here, because we have to throw exceptions in case of error which are not supported by the delegate!
		foreach(string name in node.get_object().get_members()) {
			Json.Node member = node.get_object().get_member(name);
			this.remove_all(name);
			switch(member.get_node_type()) {
				case Json.NodeType.ARRAY:
					Json.Array arr = member.get_array();
					for(int i=0;i<arr.get_length();i++) {
						Json.Node element = arr.get_element(i);
						Value val = Value( this.value_type );
					
						value_from_json( element, ref val );
						this.set(name, val.dup_object());
					}
				break;
				case Json.NodeType.NULL:
					// do nothing - just remove
				break;
				default:
					throw new JsonableError.INVALID_NODE_TYPE("Invalid node type! Array expected.");
			}
		}
	}
}
