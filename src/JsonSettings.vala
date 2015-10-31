using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.JsonSettings : GLib.Object, Serializable {
	public string path;
	
	public SerializableTreeMap<Serializable> objects { get; set; default = new SerializableTreeMap<Serializable>(); }
	
	public JsonSettings( string path ) {
		this.path = path;
	}
	
	public bool load_data( ) {
		Json.Parser parser = new Json.Parser();
		try{
			parser.load_from_file(this.path);
			this.deserialize(parser.get_root());
			return true;
		}catch(Error e) {
			stderr.printf("%s\n",e.message);
			return false;
		}
	}
	
	public bool save_data() {
		Json.Generator generator = new Json.Generator();
		generator.pretty = true;
		try{
			generator.set_root(this.serialize());
			generator.to_file(this.path);
			return true;
		}catch( Error e ) {
			stderr.printf("%s\n",e.message);
			return false;
		}
	}
	
	public string get_json( string? jsonpath = null, bool pretty = false ) throws Error {
		Json.Generator generator = new Json.Generator();
		generator.pretty = pretty;
		Json.Node node = this.serialize();
		if(jsonpath != null) {
			node = Json.Path.query(jsonpath, node);
			if(node.get_array().get_length() > 1) throw new JsonSettingsError.AMBIGUOUS("JSONPath is ambiguous!\n");
			if(node.get_array().get_length() == 0) throw new JsonSettingsError.NOT_FOUND("Node not found!\n");
			generator.set_root(node.get_array().get_element(0));
		}else{
			generator.set_root(node);
		}
		return generator.to_data(null);
	}
	
	public void set_json( string data, string? jsonpath = null ) throws Error {
		Json.Parser parser = new Json.Parser();
		parser.load_from_data(data);
		Json.Node root = parser.get_root();
		
		if(jsonpath != null) {
			Json.Node node = this.serialize();
			Json.Node subnode = Json.Path.query(jsonpath, node);
			if(subnode.get_array().get_length() > 1) throw new JsonSettingsError.AMBIGUOUS("JSONPath is ambiguous!\n");
			if(subnode.get_array().get_length() == 0) throw new JsonSettingsError.NOT_FOUND("Node not found!\n");
			if(subnode.get_array().get_element(0).get_node_type() != root.get_node_type()) throw new JsonSettingsError.WRONG_TYPE("Wrong node type!\n");
			
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
			
			this.deserialize(node);
		}else{
			this.deserialize(root);
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
}

errordomain JsonSettingsError {
	AMBIGUOUS, NOT_FOUND, WRONG_TYPE
}
