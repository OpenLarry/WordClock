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
	
	public Json.Node to_json( string path = "" ) throws JsonError {
		if(!this.value_type.is_a(typeof(Jsonable))) throw new JsonError.INVALID_VALUE_TYPE("Value does not implement interface Jsonable!");
		
		string subpath;
		string? property = JsonHelper.get_property( path, out subpath );
		
		if(property != null) {
			if(subpath!="") throw new JsonError.INVALID_PATH("Invalid path '%s'!".printf(subpath));
			
			Json.Array arr = new Json.Array();
			foreach( V entry_val in this.get(property) ) {
				Value val = Value( this.value_type );
				val.set_object( (Jsonable) entry_val );
				arr.add_element( JsonHelper.value_to_json(val) );
			}
			
			Json.Node node = new Json.Node( Json.NodeType.ARRAY );
			node.take_array(arr);
			
			return node;
		}else{
			Json.Object obj = new Json.Object();
			foreach( string entry_key in this.get_keys() ) {
				Json.Array arr = new Json.Array();
				foreach( V entry_val in this.get(entry_key) ) {
					Value val = Value( this.value_type );
					val.set_object( (Jsonable) entry_val );
					arr.add_element( JsonHelper.value_to_json(val) );
				}
				obj.set_array_member(entry_key, arr);
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
			if(subpath!="") throw new JsonError.INVALID_PATH("Invalid path '%s'!".printf(subpath));
			
			switch(node.get_node_type()) {
				case Json.NodeType.ARRAY:
					this.remove_all(property);
					Json.Array arr = node.get_array();
					for(int i=0;i<arr.get_length();i++) {
						Json.Node element = arr.get_element(i);
						Value val = Value( this.value_type );
					
						JsonHelper.value_from_json( element, ref val );
						this.set(property, val.dup_object());
					}
				break;
				case Json.NodeType.NULL:
					this.remove_all(property);
				break;
				default:
					throw new JsonError.INVALID_NODE_TYPE("Invalid node type! Array expected.");
			}
		}else{
			if( node.get_node_type() != Json.NodeType.OBJECT ) throw new JsonError.INVALID_NODE_TYPE("Invalid node type! Object expected.");
			
			// Can not use Json.Object.foreach_member here, because we have to throw exceptions in case of error which are not supported by the delegate!
			foreach(string name in node.get_object().get_members()) {
				Json.Node member = node.get_object().get_member(name);
				
				switch(member.get_node_type()) {
					case Json.NodeType.ARRAY:
						this.remove_all(name);
						Json.Array arr = member.get_array();
						for(int i=0;i<arr.get_length();i++) {
							Json.Node element = arr.get_element(i);
							Value val = Value( this.value_type );
						
							JsonHelper.value_from_json( element, ref val );
							this.set(name, val.dup_object());
						}
					break;
					case Json.NodeType.NULL:
						this.remove_all(name);
					break;
					default:
						throw new JsonError.INVALID_NODE_TYPE("Invalid node type! Array expected.");
				}
			}
		}
	}
}
