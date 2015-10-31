using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.SerializableTreeMap<V> : Gee.TreeMap<string,V>, Serializable {
	public SerializableTreeMap(owned CompareDataFunc<V>? key_compare_func = null, owned EqualDataFunc<string>? value_equal_func = null) {
		base((owned) key_compare_func, (owned) value_equal_func);
		
		if(!this.value_type.is_a(typeof(Serializable))) stderr.puts("Value does not implement Serializable interface!\n");
	}
	
	public Json.Node serialize() {
		if(!this.value_type.is_a(typeof(Serializable))) return new Json.Node( Json.NodeType.NULL );
		
		Json.Object obj = new Json.Object();
		this.foreach((entry) => {
			Value val = Value( typeof(Serializable) );
			val.set_object( (Serializable) entry.value );
			obj.set_member( entry.key, serialize_value(val) );
			return true;
		});
		
		Json.Node node = new Json.Node( Json.NodeType.OBJECT );
		node.take_object(obj);
		
		return node;
	}
	
	public void deserialize(Json.Node node) throws SerializeError {
		if(!this.value_type.is_a(typeof(Serializable))) throw new SerializeError.INVALID_CLASS_NAME("Class does not implement interface Serializable!");
		if( node.get_node_type() != Json.NodeType.OBJECT ) throw new SerializeError.INVALID_NODE_TYPE("Invalid node type! Object expected.");
		
		// Can not use Json.Object.foreach_member here, because we have to throw exceptions in case of error which are not supported by the delegate!
		foreach(string name in node.get_object().get_members()) {
			Json.Node member = node.get_object().get_member(name);
			if(member.get_node_type() != Json.NodeType.OBJECT) {
				this.unset(name);
			}else{
				Value val = Value( typeof(Serializable) );
				if(this.has_key(name)) {
					val.set_object( (Serializable) this.get(name) );
				}
				
				deserialize_value( member, ref val );
				this.set(name, val.get_object());
			}
		}
	}
}
