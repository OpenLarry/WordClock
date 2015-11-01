using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.JsonableArrayList<G> : Gee.ArrayList<G>, Jsonable {
	public JsonableArrayList(owned EqualDataFunc<G>? equal_func = null) {
		base((owned) equal_func);
		
		if(!this.element_type.is_a(typeof(Jsonable)) && !this.element_type.is_a(typeof(string))) stderr.puts("Value does not implement Jsonable interface!\n");
	}
	
	public Json.Node to_json() {
		if(!this.element_type.is_a(typeof(Jsonable)) && !this.element_type.is_a(typeof(string))) return new Json.Node( Json.NodeType.NULL );
		
		Json.Array arr = new Json.Array();
		this.foreach((entry) => {
			Value val = Value( this.element_type );
			if(this.element_type.is_a(typeof(Jsonable))) {
				val.set_object( (Jsonable) entry );
			}else{
				val.set_string( (string) entry );
			}
			arr.add_element( value_to_json(val) );
			return true;
		});
		
		
		Json.Object obj = new Json.Object();
		obj.set_array_member( "values", arr );
		
		Json.Node node = new Json.Node( Json.NodeType.OBJECT );
		node.take_object(obj);
		
		return node;
	}
	
	public void from_json(Json.Node node) throws JsonableError {
		if(!this.element_type.is_a(typeof(Jsonable)) && !this.element_type.is_a(typeof(string))) throw new JsonableError.INVALID_CLASS_NAME("Class does not implement interface Jsonable!");
		if( node.get_node_type() != Json.NodeType.OBJECT && (node.get_node_type() != Json.NodeType.VALUE || !node.get_value_type().is_a(typeof(string))) ) throw new JsonableError.INVALID_NODE_TYPE("Invalid node type! Object or string expected.");
		Json.Node arr_node = node.get_object().get_member("values");
		if(arr_node == null || arr_node.get_node_type() != Json.NodeType.ARRAY ) throw new JsonableError.INVALID_NODE_TYPE("Invalid node type! Array expected.");
		Json.Array arr = arr_node.get_array();
		
		this.clear();
		
		// Can not use Json.Array.foreach_member here, because we have to throw exceptions in case of error which are not supported by the delegate!
		for(int i=0;i<arr.get_length();i++) {
			Json.Node element = arr.get_element(i);
			Value val = Value( this.element_type );
			
			value_from_json( element, ref val );
			if(this.element_type.is_a(typeof(Jsonable))) {
				this.add(val.dup_object());
			}else{
				this.add(val.dup_string());
			}
		}
	}
}
