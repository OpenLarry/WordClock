using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
namespace WordClock.JsonHelper {
	public static void load( Jsonable obj, string path ) throws Error {
		Json.Parser parser = new Json.Parser();
		parser.load_from_file(path);
		obj.from_json(parser.get_root());
	}
	
	public static void save( Jsonable obj, string path, bool pretty = false ) throws Error {
		Json.Generator generator = new Json.Generator();
		generator.pretty = pretty;
		generator.set_root(obj.to_json());
		
		var file = GLib.File.new_for_path( path );
		var ostream = file.replace(null, true, FileCreateFlags.REPLACE_DESTINATION);
		var dostream = new GLib.DataOutputStream( ostream );
		generator.to_stream(dostream);
	}
	
	public static string to_string( Json.Node node, bool pretty = false ) {
		Json.Generator generator = new Json.Generator();
		generator.pretty = pretty;
		generator.set_root(node);
		return generator.to_data(null);
	}
	
	public static Json.Node from_string( string data ) throws Error {
		Json.Parser parser = new Json.Parser();
		parser.load_from_data(data);
		return parser.get_root();
	}
	
	public static string? get_property( string path, out string subpath ) {
		Regex regex = /^\/([0-9a-z\-,]+?)(\/.+)?$/i;
		MatchInfo match_info;
		if( !regex.match( path, 0, out match_info ) ) {
			subpath = "";
			return null;
		}
		
		subpath = match_info.fetch(2) ?? "";
		return match_info.fetch(1);
	}
	
	public static Json.Node value_to_json( Value val, string path = "" ) throws JsonError {
		Json.Node node;
		if(val.type().is_a(typeof(Jsonable))) {
			Jsonable ser = (Jsonable) val.get_object();
			if(ser == null){
				node = new Json.Node( Json.NodeType.NULL );
			}else{
				node = ser.to_json( path );
				if(node == null) node = new Json.Node( Json.NodeType.NULL );
				if(val.type() != ser.get_class().get_type() && path == "") {
					if(node.get_node_type() == Json.NodeType.OBJECT) {
						node.get_object().set_string_member( "-type", ser.get_class().get_type().name() );
					}else{
						stderr.puts("Invalid node type! Unable to append class name.\n");
					}
				}
			}
		}else if(val.type().is_object()) {
			if(path!="") throw new JsonError.INVALID_PATH("Invalid path '%s'!".printf(path));
			
			node = new Json.Node( Json.NodeType.OBJECT );
			Json.Object obj = new Json.Object();
			obj.set_string_member( "-type", val.get_object().get_class().get_type().name() );
			node.take_object(obj);
		}else{
			if(path!="") throw new JsonError.INVALID_PATH("Invalid path '%s'!".printf(path));
			
			node = new Json.Node( Json.NodeType.VALUE );
			if(val.holds(typeof(bool))) {
				node.set_boolean( val.get_boolean() );
			}else if(val.holds(typeof(char))) {
				node.set_int( val.get_schar() );
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
				throw new JsonError.INVALID_VALUE_TYPE("Invalid type: %s\n".printf(val.type().name()));
			}
		}
		
		return node;
	}
	
	public static void value_from_json( Json.Node node, ref Value val, string path = "" ) throws JsonError {
		if(val.type().is_a(typeof(Jsonable))) {
			Jsonable ser = (Jsonable) val.get_object();
			
			// destroy previous object if type is different
			if(ser != null && path == "" && node.get_node_type() == Json.NodeType.OBJECT && node.get_object().has_member("-type") && ser.get_class().get_type().name() != node.get_object().get_string_member("-type") ) {
				ser = null;
			}
			if(ser != null && path == "" && node.get_node_type() == Json.NodeType.OBJECT && !node.get_object().has_member("-type") && ser.get_class().get_type().name() != val.type().name() ) {
				ser = null;
			}
			
			if(ser == null) {
				Type type;
				if(path == "" && node.get_node_type() == Json.NodeType.OBJECT && node.get_object().has_member("-type")) {
					type = Type.from_name( node.get_object().get_string_member("-type") );
					node.get_object().remove_member("-type");
					if(!type.is_a(val.type()) || !type.is_instantiatable() || type.is_abstract() ) throw new JsonError.INVALID_CLASS_NAME("Class does not implement interface Jsonable or is abstract!");
				}else{
					type = val.type();
					if(!type.is_instantiatable() || type.is_abstract() ) throw new JsonError.UNKNOWN_CLASS_NAME("Unknwon class name! Property '-type' missing.");
				}
				
				ser = (Jsonable) Object.new( type );
				if(ser == null) throw new JsonError.INVALID_CLASS_NAME("Can not instantiate class!\n");
				
				ser.from_json(node, path);
				val.take_object(ser);
			}else{
				if(path == "" && node.get_node_type() == Json.NodeType.OBJECT && node.get_object().has_member("-type")) node.get_object().remove_member("-type");
				ser.from_json(node, path);
				val.set_object(ser);
			}
		}else if(val.type().is_object()) {
			if(path!="") throw new JsonError.INVALID_PATH("Invalid path '%s'!".printf(path));
			
			if( node.get_node_type() != Json.NodeType.OBJECT ) throw new JsonError.INVALID_NODE_TYPE("Invalid node type! Object expected.");
			if( node.get_object().get_size() > 0 ) throw new JsonError.INVALID_CLASS_NAME("Class does not implement interface Jsonable!");
		}else{
			if(path!="") throw new JsonError.INVALID_PATH("Invalid path '%s'!".printf(path));
			
			if(val.holds(typeof(bool))) {
				val.set_boolean( node.get_boolean() );
			}else if(val.holds(typeof(char))) {
				val.set_schar( (int8) node.get_int() );
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
				throw new JsonError.INVALID_VALUE_TYPE("Invalid type: %s\n".printf(val.type().name()));
			}
		}
	}
	
	public static void dump( Json.Node member_node ) { dump_foreach("root",member_node); }
	public static void dump_foreach( string member_name, Json.Node member_node, string indent = "" ) {
		switch(member_node.get_node_type()) {
			case Json.NodeType.OBJECT:
				stdout.printf("%s%s => %s\n", indent, member_name, member_node.type_name());
				member_node.get_object().foreach_member( (a,b,c) => { dump_foreach(b,c,indent+"  "); } );
			break;
			case Json.NodeType.ARRAY:
				stdout.printf("%s%s => %s\n", indent, member_name, member_node.type_name());
				member_node.get_array().foreach_element( (a,b,c) => { dump_foreach("["+b.to_string()+"]",c,indent+"  "); } );
			break;
			case Json.NodeType.NULL:
				stdout.printf("%s%s => NULL\n", indent, member_name);
			break;
			default:
				stdout.printf("%s%s => %s\n", indent, member_name, member_node.get_value().strdup_contents());
			break;
		}
	}
	
	public static bool equals( Json.Node node_a, Json.Node node_b ) {
		Json.Generator generator_a = new Json.Generator();
		Json.Generator generator_b = new Json.Generator();
		generator_a.set_root(node_a);
		generator_b.set_root(node_b);
		return generator_a.to_data(null) == generator_b.to_data(null);
	}
	
	public static bool intersection_equals( Json.Node node_a, Json.Node node_b ) {
		if( node_a.get_node_type() != node_b.get_node_type() ) return false;
		
		switch(node_a.get_node_type()) {
			case Json.NodeType.OBJECT:
				foreach(unowned string name in node_a.get_object().get_members()) {
					if( !node_b.get_object().has_member( name ) ) continue;
					if( !intersection_equals(node_a.get_object().get_member(name),node_b.get_object().get_member(name)) ) return false;
				}
			break;
			case Json.NodeType.ARRAY:
				if( node_a.get_array().get_length() != node_b.get_array().get_length() ) return false;
				
				for(int i=0;i<node_a.get_array().get_length();i++) {
					if( !intersection_equals(node_a.get_array().get_element(i),node_b.get_array().get_element(i)) ) return false;
				}
			break;
			case Json.NodeType.NULL:
			break;
			default:
				Value a = node_a.get_value(), b = node_b.get_value();
				
				if(a.holds(typeof(double)) != b.holds(typeof(double))) {
					Value c = Value(typeof(double));
					
					if(a.holds(typeof(double))) {
						return b.transform(ref c) && a.get_double() == c.get_double();
					}else{
						return a.transform(ref c) && b.get_double() == c.get_double();
					}
				}else if(a.holds(typeof(float)) != b.holds(typeof(float))) {
					Value c = Value(typeof(float));
					if(a.holds(typeof(float))) {
						return b.transform(ref c) && a.get_float() == c.get_float();
					}else{
						return a.transform(ref c) && b.get_float() == c.get_float();
					}
				}else {
					return a.strdup_contents() == b.strdup_contents();
				}
		}
		
		return true;
	}
}

public errordomain WordClock.JsonError {
	INVALID_PROPERTY,
	INVALID_NODE_TYPE,
	UNKNOWN_CLASS_NAME,
	INVALID_CLASS_NAME,
	INVALID_VALUE_TYPE,
	INVALID_PATH,
	IMMUTABLE_KEY
}
