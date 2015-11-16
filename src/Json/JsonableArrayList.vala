using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.JsonableArrayList<G> : Gee.ArrayList<G>, Jsonable {
	public JsonableArrayList(owned EqualDataFunc<G>? equal_func = null) {
		base((owned) equal_func);
		
		if(!this.element_type.is_a(typeof(Jsonable))) stderr.puts("Value does not implement Jsonable interface!\n");
	}
	
	public Json.Node to_json( string path = "" ) throws JsonError {
		if(!this.element_type.is_a(typeof(Jsonable))) throw new JsonError.INVALID_VALUE_TYPE("Value does not implement interface Jsonable!");
		
		string subpath;
		string? property = JsonHelper.get_property( path, out subpath );
		
		if(property != null) {
			if(int.parse(property) >= this.size) throw new JsonError.INVALID_PATH("Invalid property '%s'!".printf(property));
			Value val = Value( this.element_type );
			val.set_object( (Jsonable) this.get(int.parse(property)) );
			return JsonHelper.value_to_json(val,subpath);
		}else{
			Json.Array arr = new Json.Array();
			foreach(G entry in this) {
				Value val = Value( this.element_type );
				val.set_object( (Jsonable) entry );
				arr.add_element( JsonHelper.value_to_json(val) );
			}
			
			Json.Node node = new Json.Node( Json.NodeType.ARRAY );
			node.take_array(arr);
			
			return node;
		}
	}
	
	public void from_json(Json.Node node, string path = "") throws JsonError {
		if(!this.element_type.is_a(typeof(Jsonable))) throw new JsonError.INVALID_VALUE_TYPE("Value does not implement interface Jsonable!");
		
		string subpath;
		string? property = JsonHelper.get_property( path, out subpath );
		
		if(property != null) {
			if(int.parse(property) >= this.size) throw new JsonError.INVALID_PATH("Invalid property '%s'!".printf(property));
			
			Value val = Value( this.element_type );
			val.set_object( (Jsonable) this.get(int.parse(property)) );
			JsonHelper.value_from_json( node, ref val, subpath );
			this.set(int.parse(property), val.dup_object());
		}else{
			if( node.get_node_type() != Json.NodeType.ARRAY ) throw new JsonError.INVALID_NODE_TYPE("Invalid node type! Array expected.");
			Json.Array arr = node.get_array();
			
			this.clear();
			
			// Can not use Json.Array.foreach_member here, because we have to throw exceptions in case of error which are not supported by the delegate!
			for(int i=0;i<arr.get_length();i++) {
				Json.Node element = arr.get_element(i);
				Value val = Value( this.element_type );
				
				JsonHelper.value_from_json( element, ref val );
				this.add(val.dup_object());
			}
		}
	}
}
