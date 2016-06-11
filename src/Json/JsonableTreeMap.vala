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
	
	private string[] immutable_keys = {};
	
	public void set_keys_immutable() {
		this.immutable_keys = this.keys.to_array();
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
				
				string type_before = "";
				if(this.has_key(property)) {
					val.take_object( (Jsonable) this.get(property) );
					type_before = val.get_object().get_class().get_type().name();
				}
				JsonHelper.value_from_json( node, ref val, subpath );
				string type_after = val.get_object().get_class().get_type().name();
				if(property in this.immutable_keys && type_after != type_before) throw new JsonError.IMMUTABLE_KEY("Can't change object type! Key %s is immutable!".printf(property));
				
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
					
					string type_before = "";
					if(this.has_key(name)) {
						val.take_object( (Jsonable) this.get(name) );
						type_before = val.get_object().get_class().get_type().name();
					}
					JsonHelper.value_from_json( member, ref val );
					string type_after = val.get_object().get_class().get_type().name();
					if(name in this.immutable_keys && type_after != type_before) throw new JsonError.IMMUTABLE_KEY("Can't change object type! Key %s is immutable!".printf(name));
					
					this.set(name, val.dup_object());
				}
			}
			
			// Remove elements
			string[] keys = {};
			foreach(string key in this.keys) {
				if(!node.get_object().has_member(key) && !(key in this.immutable_keys)) {
					keys += key;
				}
			}
			foreach(string key in keys) {
				this.unset(key);
			}
		}
	}
}
