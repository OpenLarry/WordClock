using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.JsonableTreeMap<V> : Gee.TreeMap<string,V>, Jsonable {
	public JsonableTreeMap(owned CompareDataFunc<V>? key_compare_func = null, owned EqualDataFunc<string>? value_equal_func = null) {
		base((owned) key_compare_func, (owned) value_equal_func);
		
		if(!this.value_type.is_a(typeof(Jsonable))) stderr.puts("Value does not implement Jsonable interface!\n");
	}
	
	public Json.Node to_json() {
		if(!this.value_type.is_a(typeof(Jsonable))) return new Json.Node( Json.NodeType.NULL );
		
		Json.Object obj = new Json.Object();
		this.foreach((entry) => {
			Value val = Value( typeof(Jsonable) );
			val.set_object( (Jsonable) entry.value );
			obj.set_member( entry.key, value_to_json(val) );
			return true;
		});
		
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
			if(member.get_node_type() != Json.NodeType.OBJECT) {
				this.unset(name);
			}else{
				Value val = Value( typeof(Jsonable) );
				if(this.has_key(name)) {
					val.take_object( (Jsonable) this.get(name) );
				}
				
				value_from_json( member, ref val );
				this.set(name, val.dup_object());
			}
		}
	}
}
