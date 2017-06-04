using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 *
 * This combined class of TreeMap and ArrayList is needed because it is impossible to instantiate generic objects at runtime correctly in vala
 * => JsonHelper can not create JsonableArrayList inside JsonableTreeMap on its own
 * => JsonableTreeMultiMap does not fulfill this purpose because ordered values are needed
 */
public class WordClock.JsonableTreeMapArrayList<V> : JsonableTreeMap<JsonableArrayList<V>>, Jsonable {
	public JsonableTreeMapArrayList(owned CompareDataFunc<string>? key_compare_func = null, owned EqualDataFunc<V>? value_equal_func = null) {
		base((owned) key_compare_func, (owned) value_equal_func);
		
		if(!this.value_type.is_a(typeof(Jsonable))) error("Value does not implement Jsonable interface!\n");
		if(!typeof(V).is_a(typeof(Jsonable))) error("Value does not implement Jsonable interface!\n");
	}
	
	public new void from_json(Json.Node node, string path = "") throws JsonError {
		if(!this.value_type.is_a(typeof(Jsonable))) throw new JsonError.INVALID_VALUE_TYPE("Value does not implement interface Jsonable!");
		
		string subpath;
		string? property = JsonHelper.get_property( path, out subpath );
		
		if(property != null) {
			if(subpath == "" && node.get_node_type() == Json.NodeType.NULL) {
				this.unset(property);
			}else{
				Value val = Value( this.value_type );
				if(this.has_key(property)) {
					val.take_object( (JsonableArrayList<V>) this.get(property) );
				}else{
					// instantiate JsonableArrayList with generic type
					val.take_object( new JsonableArrayList<V>() );
				}
				JsonHelper.value_from_json( node, ref val, subpath );
				this.set(property, (JsonableArrayList<V>) val.dup_object());
			}
		}else{
			if( node.get_node_type() != Json.NodeType.OBJECT ) throw new JsonError.INVALID_NODE_TYPE("Invalid node type! Object expected.");
			
			// Can not use Json.Object.foreach_member here, because we have to throw exceptions in case of error which are not supported by the delegate!
			foreach(string name in node.get_object().get_members()) {
				Json.Node member = node.get_object().get_member(name);
				if(member.get_node_type() == Json.NodeType.NULL) {
					this.unset(name);
				}else{
					Value val = Value( this.value_type );
					if(this.has_key(name)) {
						val.take_object( (JsonableArrayList<V>) this.get(name) );
					}else{
						// instantiate JsonableArrayList with generic type
						val.take_object( new JsonableArrayList<V>() );
					}
					JsonHelper.value_from_json( member, ref val );
					this.set(name, (JsonableArrayList<V>) val.dup_object());
				}
			}
			
			// Remove elements
			string[] keys = {};
			foreach(string key in this.keys) {
				if(!node.get_object().has_member(key)) keys += key;
			}
			foreach(string key in keys) {
				this.unset(key);
			}
		}
	}
}
