using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 *
 * Normally, this class is not necessary. But: Json.gobject_serialize and Json.gobject_deserialize are not working reliably
 * (segfaults, null pointers, ...) and they are too unconvenient. => I do it by myself.
 */

public interface WordClock.Jsonable : GLib.Object {
	/**
	* Encodes object to json
	* @return json node
	*/
	public virtual Json.Node to_json( string path = "" ) throws JsonError {
		string subpath;
		string? property = JsonHelper.get_property( path, out subpath );
		
		if(property != null) {
			ParamSpec? pspec = this.get_class().find_property(property);
			if(pspec == null) throw new JsonError.INVALID_PATH("Invalid property '%s'!".printf(property));
			
			Value val = Value(pspec.value_type);
			this.get_property(pspec.get_name(), ref val);
			return JsonHelper.value_to_json( val, subpath );
		}else{
			Json.Object obj = new Json.Object();
			
			foreach(unowned ParamSpec pspec in this.get_class().list_properties()) {
				Value val = Value(pspec.value_type);
				this.get_property(pspec.get_name(), ref val);
				
				obj.set_member( pspec.get_name(), JsonHelper.value_to_json( val ) );
			}
			
			Json.Node node = new Json.Node( Json.NodeType.OBJECT );
			node.take_object(obj);
			
			return node;
		}
	}
	
	/**
	 * Sets object properties by json
	 * @param node json node
	 */
	public virtual void from_json( Json.Node node, string path = "" ) throws JsonError {
		string subpath;
		string? property = JsonHelper.get_property( path, out subpath );
		
		if(property != null) {
			ParamSpec? pspec = this.get_class().find_property(property);
			if(pspec == null) throw new JsonError.INVALID_PATH("Invalid property '%s'!".printf(property));
			
			Value val = Value(pspec.value_type);
			this.get_property(pspec.get_name(), ref val);
			JsonHelper.value_from_json( node, ref val, subpath );
			this.set_property(pspec.get_name(), val);
		}else{
			if( node.get_node_type() != Json.NodeType.OBJECT ) throw new JsonError.INVALID_NODE_TYPE("Invalid node type! Object expected.");
			
			// Can not use Json.Object.foreach_member here, because we have to throw exceptions in case of error which are not supported by the delegate!
			foreach(string name in node.get_object().get_members()) {
				Json.Node member = node.get_object().get_member(name);
				
				ParamSpec? pspec = this.get_class().find_property(name);
				if(pspec == null) throw new JsonError.INVALID_PROPERTY("Invalid property '%s'!".printf(name));
				
				Value val = Value(pspec.value_type);
				this.get_property(pspec.get_name(), ref val);
				JsonHelper.value_from_json( member, ref val );
				this.set_property(pspec.get_name(), val);
			}
		}
	}
}
