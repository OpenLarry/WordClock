using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 *
 * Normally, this class is not necessary. But: Json.gobject_serialize and Json.gobject_deserialize are not working reliably
 * (segfaults, null pointers, ...) and they are too unconvenient. => I do it by myself.
 */

public interface WordClock.Jsonable : GLib.Object {
	
	public virtual Json.Node to_json() {
		Json.Object obj = new Json.Object();
		
		foreach(unowned ParamSpec pspec in this.get_class().list_properties()) {
			Value val = Value(pspec.value_type);
			this.get_property(pspec.get_name(), ref val);
			
			obj.set_member( pspec.get_name(), value_to_json( val ) );
		}
		
		Json.Node node = new Json.Node( Json.NodeType.OBJECT );
		node.take_object(obj);
		
		return node;
	}
	
	public virtual void from_json( Json.Node node ) throws JsonableError {
		if( node.get_node_type() != Json.NodeType.OBJECT ) throw new JsonableError.INVALID_NODE_TYPE("Invalid node type! Object expected.");
		
		// Can not use Json.Object.foreach_member here, because we have to throw exceptions in case of error which are not supported by the delegate!
		foreach(string name in node.get_object().get_members()) {
			Json.Node member = node.get_object().get_member(name);
			
			ParamSpec? pspec = this.get_class().find_property(name.replace("-","_"));
			if(pspec == null) throw new JsonableError.INVALID_PROPERTY("Invalid property '%s'!".printf(name.replace("-","_")));
			
			Value val = Value(pspec.value_type);
			this.get_property(pspec.get_name(), ref val);
			value_from_json( member, ref val );
			this.set_property(pspec.get_name(), val);
		}
	}
	
	public static Json.Node value_to_json( Value val ) {
		Json.Node node;
		if(val.type().is_a(typeof(Jsonable))) {
			Jsonable ser = (Jsonable) val.get_object();
			if(ser == null){
				node = new Json.Node( Json.NodeType.NULL );
			}else{
				node = ser.to_json();
				if(node == null) node = new Json.Node( Json.NodeType.NULL );
				if(node.get_node_type() == Json.NodeType.OBJECT) {
					node.get_object().set_string_member( "-type", ser.get_class().get_type().name() );
				}else{
					stderr.puts("Invalid node type! Unable to append class name.\n");
				}
			}
		}else if(val.type().is_object()) {
			node = new Json.Node( Json.NodeType.OBJECT );
			Json.Object obj = new Json.Object();
			obj.set_string_member( "-type", val.get_object().get_class().get_type().name() );
			node.take_object(obj);
		}else{
			node = new Json.Node( Json.NodeType.VALUE );
			if(val.holds(typeof(bool))) {
				node.set_boolean( val.get_boolean() );
			}else if(val.holds(typeof(char))) {
				node.set_int( val.get_char() );
			}else if(val.holds(typeof(uchar))) {
				node.set_int( val.get_uchar() );
			}else if(val.holds(typeof(int))) {
				node.set_int( val.get_int() );
			}else if(val.holds(typeof(uint))) {
				node.set_int( val.get_uint() );
			}else if(val.holds(typeof(long))) {
				node.set_int( val.get_long() );
			}else if(val.holds(typeof(ulong))) {
				node.set_int( val.get_ulong() );
			}else if(val.holds(typeof(int64))) {
				node.set_int( val.get_int64() );
			}else if(val.holds(typeof(uint64))) {
				// convert to signed integer
				node.set_int( (int64) val.get_uint64() );
			}else if(val.holds(typeof(float))) {
				node.set_double( val.get_float() );
			}else if(val.holds(typeof(double))) {
				node.set_double( val.get_double() );
			}else if(val.holds(typeof(string))) {
				node.set_string( val.get_string() );
			}else{
				stderr.printf("Invalid type: %s\n", val.type().name());
				node = new Json.Node( Json.NodeType.NULL );
			}
		}
		
		return node;
	}
	
	public static void value_from_json( Json.Node node, ref Value val ) throws JsonableError {
		if(val.type().is_a(typeof(Jsonable))) {
			Jsonable ser = (Jsonable) val.get_object();
			if(ser == null) {
				if(node.get_node_type() != Json.NodeType.OBJECT) throw new JsonableError.INVALID_NODE_TYPE("Invalid node type! Object expected.");
				if(!node.get_object().has_member("-type")) throw new JsonableError.UNKNOWN_CLASS_NAME("Unknwon class name! Property '-type' missing.");
				if(!Type.from_name( node.get_object().get_string_member("-type") ).is_a(typeof(Jsonable)) ) throw new JsonableError.INVALID_CLASS_NAME("Class does not implement interface Jsonable!");
				ser = (Jsonable) Object.new( Type.from_name( node.get_object().get_string_member("-type") ) );
				
				if(ser == null) throw new JsonableError.INVALID_CLASS_NAME("Can not instantiate class!\n");
				
				
				if(node.get_object().has_member("-type")) node.get_object().remove_member("-type");
				ser.from_json(node);
				val.take_object(ser);
			}else{
				if(node.get_object().has_member("-type")) node.get_object().remove_member("-type");
				ser.from_json(node);
				val.set_object(ser);
			}
		}else if(val.type().is_object()) {
			if( node.get_node_type() != Json.NodeType.OBJECT ) throw new JsonableError.INVALID_NODE_TYPE("Invalid node type! Object expected.");
			if( node.get_object().get_size() > 0 ) throw new JsonableError.INVALID_CLASS_NAME("Class does not implement interface Jsonable!");
		}else{
			if(val.holds(typeof(bool))) {
				val.set_boolean( node.get_boolean() );
			}else if(val.holds(typeof(char))) {
				val.set_char( (char) node.get_int() );
			}else if(val.holds(typeof(uchar))) {
				val.set_uchar( (uchar) node.get_int() );
			}else if(val.holds(typeof(int))) {
				val.set_int( (int) node.get_int() );
			}else if(val.holds(typeof(uint))) {
				val.set_uint( (uint) node.get_int() );
			}else if(val.holds(typeof(long))) {
				val.set_long( (long) node.get_int() );
			}else if(val.holds(typeof(ulong))) {
				val.set_ulong( (ulong) node.get_int() );
			}else if(val.holds(typeof(int64))) {
				val.set_int64( node.get_int() );
			}else if(val.holds(typeof(uint64))) {
				val.set_uint64( node.get_int() );
			}else if(val.holds(typeof(float))) {
				val.set_float( (float) node.get_double() );
			}else if(val.holds(typeof(double))) {
				val.set_double( node.get_double() );
			}else if(val.holds(typeof(string))) {
				val.set_string( node.get_string() );
			}else{
				throw new JsonableError.INVALID_VALUE_TYPE("Invalid type: %s\n".printf(val.type().name()));
			}
		}
	}
}

public errordomain WordClock.JsonableError {
	INVALID_PROPERTY, INVALID_NODE_TYPE, UNKNOWN_CLASS_NAME, INVALID_CLASS_NAME, INVALID_VALUE_TYPE
}
