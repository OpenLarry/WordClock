using JsonWrapper;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class JsonWrapper.Node : GLib.Object {
	internal unowned Json.Node node;
	internal Node? parent = null;
	internal Value? key = null;
	
	// we want to keep an OWNED root Json.Node, if Node.new(), Node.from_file() or Node.from_string() is used
	private Json.Node root;
	
	// cannot use name "size" here, otherwise vala uses size() / get() iterator protocol
	public uint length {
		get {
			switch(this.node.get_node_type()) {
				case Json.NodeType.OBJECT:
					return this.node.get_object().get_size();
				case Json.NodeType.ARRAY:
					return this.node.get_array().get_length();
				case Json.NodeType.VALUE:
					return 1;
				case Json.NodeType.NULL:
					return 0;
				default: // should not happen
					return 0;
			}
		}
	}
	
	public Node( Json.Node node ) throws JsonWrapper.Error {
		this.node = node;
		this.check_null();
	}
	
	private Node.with_parent( Json.Node node, Node parent, Value key ) throws JsonWrapper.Error {
		this( node );
		this.parent = parent;
		this.key = key;
	}
	
	public Node.empty( Json.NodeType type ) throws JsonWrapper.Error {
		Json.Node root = new Json.Node( type );
		
		if( type == Json.NodeType.OBJECT ) root.set_object( new Json.Object() );
		if( type == Json.NodeType.ARRAY ) root.set_array( new Json.Array() );
		
		this( root );
		this.root = (owned) root;
	}
	
	public Node.value( Value? val ) throws JsonWrapper.Error {
		if(val == null) {
			this.root = new Json.Node( Json.NodeType.NULL );
			this.node = this.root;
		} else if(val.type().is_a(typeof(Json.Node))) {
			this.root = (Json.Node) val;
			this.node = this.root;
			this.check_null();
		} else if(val.type().is_a(typeof(Node))) {
			Node node = (Node) val;
			this.node = node.node;
		} else {
			this.root = new Json.Node( Json.NodeType.VALUE );
			this.node = this.root;
			this.node.set_value( val );
		}
	}
	
	public Node.from_json_string( string data ) throws GLib.Error {
		Json.Parser parser = new Json.Parser();
		parser.load_from_data(data);
		Json.Node root = parser.get_root();
		
		this( root );
		this.root = (owned) root;
	}
	
	public Node.from_json_file( string path ) throws GLib.Error {
		Json.Parser parser = new Json.Parser();
		parser.load_from_file(path);
		Json.Node root = parser.get_root();
		
		this( root );
		this.root = (owned) root;
	}
	
	public string to_json_string(bool pretty = false) throws GLib.Error {
		Json.Generator generator = new Json.Generator();
		generator.pretty = pretty;
		generator.set_root(this.node);
		return generator.to_data(null);
	}
	
	public void to_json_file(string path, bool pretty = false, bool make_backup = false) throws GLib.Error {
		Json.Generator generator = new Json.Generator();
		generator.pretty = pretty;
		generator.set_root(this.node);
		
		var file = GLib.File.new_for_path( path );
		var ostream = file.replace(null, make_backup, FileCreateFlags.REPLACE_DESTINATION);
		var dostream = new GLib.DataOutputStream( ostream );
		generator.to_stream(dostream);
	}
	
	private void check_null() throws JsonWrapper.Error {
		if( this.node == null ) throw new JsonWrapper.Error.NULL("Node is null");
		if( this.node.get_node_type() == Json.NodeType.OBJECT && this.node.get_object() == null ) throw new JsonWrapper.Error.NULL("Object is null");
		if( this.node.get_node_type() == Json.NodeType.ARRAY && this.node.get_array() == null ) throw new JsonWrapper.Error.NULL("Array is null");
	}
	
	public new Node get( Value key ) throws JsonWrapper.Error {
		switch(this.node.get_node_type()) {
			case Json.NodeType.OBJECT:
				Value key_string = Value(typeof(string));
				if( !key.transform(ref key_string) ) throw new JsonWrapper.Error.INVALID_KEY_TYPE("Invalid key type: %s".printf(key.type_name()));
				if( !this.node.get_object().has_member( (string) key_string ) ) throw new JsonWrapper.Error.NOT_FOUND("No member: %s".printf((string) key_string));
				
				return new Node.with_parent( this.node.get_object().get_member( (string) key_string ), this, key );
			case Json.NodeType.ARRAY:
				Value key_uint = Value(typeof(uint));
				if( !key.transform(ref key_uint) ) throw new JsonWrapper.Error.INVALID_KEY_TYPE("Invalid key type: %s".printf(key.type_name()));
				if( (uint) key_uint >= this.length ) throw new JsonWrapper.Error.NOT_FOUND("No element: %u".printf((uint) key_uint));
				
				return new Node.with_parent( this.node.get_array().get_element( (uint) key_uint ), this, key );
			case Json.NodeType.VALUE:
			case Json.NodeType.NULL:
				throw new JsonWrapper.Error.INVALID_NODE_TYPE("Expected array or object, got: %s".printf(this.node.get_node_type().to_string()));
			default: // should not happen
				throw new JsonWrapper.Error.INVALID_NODE_TYPE("Unexpected node type, got: %s".printf(this.node.get_node_type().to_string()));
		}
	}
	
	public new void set( Value key, Value? value ) throws JsonWrapper.Error {
		try { 
			this[key].set_value(value);
		} catch ( JsonWrapper.Error e ) {
			if( e is JsonWrapper.Error.NOT_FOUND ) {
				switch(this.node.get_node_type()) {
					case Json.NodeType.OBJECT:
						// no further checks are necessary, everything should have been checked in get function
						Value key_string = Value(typeof(string));
						key.transform(ref key_string);
						
						this.node.get_object().set_member( (string) key_string, new Json.Node(Json.NodeType.NULL) );
						this[key] = value;
						break;
					case Json.NodeType.ARRAY:
						// no further checks are necessary, everything should have been checked in get function
						this.node.get_array().add_element( new Json.Node(Json.NodeType.NULL) );
						this[this.length-1] = value;
						break;
					default: // should not happen
						throw new JsonWrapper.Error.INVALID_NODE_TYPE("Unexpected node type, got: %s".printf(this.node.get_node_type().to_string()));
				}
			} else {
				throw e;
			}
		}
	}
	
	public void set_value( Value? value ) throws JsonWrapper.Error {
		if(value == null) {
			this.node.init( Json.NodeType.NULL );
		} else if(value.type().is_a(typeof(Node))) {
			Node node = (Node) value;
			if(this == node || this.node == node.node) return;
			
			this.node.init( node.node.get_node_type() );
			
			switch(node.node.get_node_type()) {
				case Json.NodeType.OBJECT:
					this.node.set_object( node.node.get_object() );
					break;
				case Json.NodeType.ARRAY:
					this.node.set_array( node.node.get_array() );
					break;
				case Json.NodeType.VALUE:
					this.node.set_value( node.node.get_value() );
					break;
				case Json.NodeType.NULL:
					break;
				default: // should not happen
					throw new JsonWrapper.Error.INVALID_NODE_TYPE("Unexpected node type, got: %s".printf(this.node.get_node_type().to_string()));
			}
		} else if(value.type().is_a(typeof(Json.Node))) {
			this.set_value( new Node.value(value) );
		} else {
			this.node.init( Json.NodeType.VALUE );
			this.node.set_value( value );
		}
	}
	
	public string to_string() throws JsonWrapper.Error {
		Value val_string = Value(typeof(string));
		this.to_value( ref val_string );
		
		return (string) val_string;
	}
	
	public void to_value( ref Value val ) throws JsonWrapper.Error {
		if( !this.get_value().transform( ref val ) ) throw new JsonWrapper.Error.INVALID_VALUE_TYPE("Expected %s, got: %s".printf(val.type_name(), this.node.get_value().type_name()));
	}
	
	public Value get_value() throws JsonWrapper.Error {
		if( this.node.get_node_type() != Json.NodeType.VALUE ) throw new JsonWrapper.Error.INVALID_NODE_TYPE("Expected value, got: %s".printf(this.node.get_node_type().to_string()));
		
		return this.node.get_value();
	}
	
	public Value get_typed_value<T>() throws JsonWrapper.Error {
		Value val = Value(typeof(T));
		this.to_value(ref val);
		
		return val;
	}
	
	/* 
	 * Valas generic support is terrible, there is no chance to return generic T[] arrays.
	 * Only e.g. int?[] works, but converting to int[] is terrible also...
	 */
	public int64[] get_int64_array() throws JsonWrapper.Error {
		if( this.node.get_node_type() != Json.NodeType.ARRAY ) throw new JsonWrapper.Error.INVALID_NODE_TYPE("Expected array, got: %s".printf(this.node.get_node_type().to_string()));
		
		int64[] vals = {};
		foreach(unowned Json.Node node in this.node.get_array().get_elements()) {
			Value val = Value(typeof(int64));
			new Node(node).to_value(ref val);
			vals += (int64) val;
		}
		
		return vals;
	}
	public uint8[] get_uint8_array() throws JsonWrapper.Error {
		if( this.node.get_node_type() != Json.NodeType.ARRAY ) throw new JsonWrapper.Error.INVALID_NODE_TYPE("Expected array, got: %s".printf(this.node.get_node_type().to_string()));
		
		uint8[] vals = {};
		foreach(unowned Json.Node node in this.node.get_array().get_elements()) {
			Value val = Value(typeof(uint8));
			new Node(node).to_value(ref val);
			vals += (uint8) val;
		}
		
		return vals;
	}
	
	public Iterator iterator() throws JsonWrapper.Error {
		switch(this.node.get_node_type()) {
			case Json.NodeType.OBJECT:
				return new ObjectIterator( this );
			case Json.NodeType.ARRAY:
				return new ArrayIterator( this );
			default:
				throw new JsonWrapper.Error.INVALID_NODE_TYPE("Expected array or object, got: %s".printf(this.node.get_node_type().to_string()));
		}
	}
	
	public bool equals( Value other ) throws JsonWrapper.Error {
		Node other_node = new Node.value(other);
		return this.node.equal(other_node.node);
	}
	
	public bool contains( Value needle ) throws JsonWrapper.Error {
		foreach( JsonWrapper.Entry entry in this ) {
			if( entry.value.equals(needle) ) return true;
		}
		return false;
	}
	
	public void remove() throws JsonWrapper.Error {
		if( this.parent == null ) throw new JsonWrapper.Error.INVALID_NODE_TYPE("Node has no parent");
		
		switch( this.parent.node.get_node_type() ) {
			case Json.NodeType.OBJECT:
				Value key_string = Value(typeof(string));
				if( !key.transform(ref key_string) ) throw new JsonWrapper.Error.INVALID_KEY_TYPE("Invalid key type: %s".printf(key.type_name()));
				if( !this.parent.node.get_object().has_member( (string) key_string ) ) throw new JsonWrapper.Error.NOT_FOUND("No member: %s".printf((string) key_string));
				this.parent.node.get_object().remove_member((string) key_string);
				
				break;
			case Json.NodeType.ARRAY:
				Value key_uint = Value(typeof(uint));
				if( !key.transform(ref key_uint) ) throw new JsonWrapper.Error.INVALID_KEY_TYPE("Invalid key type: %s".printf(key.type_name()));
				if( (uint) key_uint >= this.parent.length ) throw new JsonWrapper.Error.NOT_FOUND("No element: %u".printf((uint) key_uint));
				this.parent.node.get_array().remove_element((uint) key_uint);
				
				break;
			default:
				throw new JsonWrapper.Error.INVALID_NODE_TYPE("Expected array or object as parent, got: %s".printf(this.parent.node.get_node_type().to_string()));
		}
		
		this.parent = null;
		this.key = null;
	}
	
	
	public bool has( Value key ) throws JsonWrapper.Error {
		switch(this.node.get_node_type()) {
			case Json.NodeType.OBJECT:
				Value key_string = Value(typeof(string));
				if( !key.transform(ref key_string) ) throw new JsonWrapper.Error.INVALID_KEY_TYPE("Invalid key type: %s".printf(key.type_name()));
				return this.node.get_object().has_member( (string) key_string );
			case Json.NodeType.ARRAY:
				Value key_uint = Value(typeof(uint));
				if( !key.transform(ref key_uint) ) throw new JsonWrapper.Error.INVALID_KEY_TYPE("Invalid key type: %s".printf(key.type_name()));
				return (uint) key_uint < this.length;
			case Json.NodeType.VALUE:
			case Json.NodeType.NULL:
				throw new JsonWrapper.Error.INVALID_NODE_TYPE("Expected array or object, got: %s".printf(this.node.get_node_type().to_string()));
			default: // should not happen
				throw new JsonWrapper.Error.INVALID_NODE_TYPE("Unexpected node type, got: %s".printf(this.node.get_node_type().to_string()));
		}
	}
	
	// testing
	public void dump() {
		WordClock.JsonHelper.dump( this.node );
	}
}

public errordomain JsonWrapper.Error {
	NULL,
	NOT_FOUND,
	INVALID_KEY_TYPE,
	INVALID_NODE_TYPE,
	INVALID_VALUE_TYPE
}
