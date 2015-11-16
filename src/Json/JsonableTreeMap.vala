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
	
	public Json.Node to_json( string path = "" ) throws JsonError {
		if(!this.value_type.is_a(typeof(Jsonable))) throw new JsonError.INVALID_VALUE_TYPE("Value does not implement interface Jsonable!");
		
		string subpath;
		string? property = JsonHelper.get_property( path, out subpath );
		
		if(property != null) {
			if(!this.has_key(property)) throw new JsonError.INVALID_PATH("Invalid property '%s'!".printf(property));
			
			Value val = Value( this.value_type );
			val.set_object( (Jsonable) this[property] );
			return JsonHelper.value_to_json( val, subpath );
		}else{
			Json.Object obj = new Json.Object();
			foreach(Map.Entry<string,V> entry in this.entries) {
				Value val = Value( this.value_type );
				val.set_object( (Jsonable) entry.value );
				obj.set_member( entry.key, JsonHelper.value_to_json(val) );
			}
			
			Json.Node node = new Json.Node( Json.NodeType.OBJECT );
			node.take_object(obj);
			
			return node;
		}
	}
	
	public void from_json(Json.Node node, string path = "") throws JsonError {
		if(!this.value_type.is_a(typeof(Jsonable))) throw new JsonError.INVALID_VALUE_TYPE("Value does not implement interface Jsonable!");
		
		string subpath;
		string? property = JsonHelper.get_property( path, out subpath );
		
		if(property != null) {
			if(subpath == "" && node.get_node_type() == Json.NodeType.NULL) {
				this.unset(property);
			}else{
				Value val = Value( this.value_type );
				if(this.has_key(property)) {
					val.take_object( (Jsonable) this.get(property) );
				}
				JsonHelper.value_from_json( node, ref val, subpath );
				this.set(property, val.dup_object());
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
						val.take_object( (Jsonable) this.get(name) );
					}
					JsonHelper.value_from_json( member, ref val );
					this.set(name, val.dup_object());
				}
			}
		}
	}
}
