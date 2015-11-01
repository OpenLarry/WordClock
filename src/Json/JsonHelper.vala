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
		generator.to_file(path);
	}
	
	public static string get_string( Jsonable obj, string? jsonpath = null, bool pretty = false ) throws Error {
		Json.Generator generator = new Json.Generator();
		generator.pretty = pretty;
		generator.set_root(get_json(obj,jsonpath));
		return generator.to_data(null);
	}
	
	public static Json.Node get_json( Jsonable obj, string? jsonpath = null ) throws Error {
		Json.Node node = obj.to_json();
		if(jsonpath != null) {
			node = Json.Path.query(jsonpath, node);
			if(node.get_array().get_length() > 1) throw new JsonHelperError.AMBIGUOUS("JSONPath is ambiguous!\n");
			if(node.get_array().get_length() == 0) throw new JsonHelperError.NOT_FOUND("Node not found!\n");
			return node.get_array().get_element(0);
		}else{
			return node;
		}
	}
	
	public static void set_string( Jsonable obj, string data, string? jsonpath = null ) throws Error {
		Json.Parser parser = new Json.Parser();
		parser.load_from_data(data);
		Json.Node root = parser.get_root();
		
		set_json( obj, root, jsonpath );
	}
	
	public static void set_json( Jsonable obj, Json.Node root, string? jsonpath = null ) throws Error {
		if(jsonpath != null) {
			Json.Node node = obj.to_json();
			Json.Node subnode = Json.Path.query(jsonpath, node);
			if(subnode.get_array().get_length() > 1) throw new JsonHelperError.AMBIGUOUS("JSONPath is ambiguous!\n");
			if(subnode.get_array().get_length() == 0) throw new JsonHelperError.NOT_FOUND("Node not found!\n");
			if(subnode.get_array().get_element(0).get_node_type() != root.get_node_type()) throw new JsonHelperError.WRONG_TYPE("Wrong node type!\n");
			
			switch(subnode.get_array().get_element(0).get_node_type()) {
				case Json.NodeType.OBJECT:
					root.get_object().foreach_member((obj,name,node) => {
						subnode.get_array().get_element(0).get_object().set_member(name,node);
					});
				break;
				case Json.NodeType.ARRAY:
					subnode.get_array().get_element(0).take_array( root.dup_array() );
				break;
				case Json.NodeType.VALUE:
					subnode.get_array().get_element(0).set_value( root.get_value() );
				break;
			}
			
			obj.from_json(node);
		}else{
			obj.from_json(root);
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
}

errordomain JsonHelperError {
	AMBIGUOUS, NOT_FOUND, WRONG_TYPE
}
