using JsonWrapper;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class JsonWrapper.Entry : GLib.Object {
	public Value key { get; construct set; }
	public Node value { get; construct set; }
	
	internal Entry( Value key, Node value) {
		Object( key: key, value: value );
	}
	
	public string get_member_name() throws JsonWrapper.Error {
		 if(!this.key.holds(typeof(string))) throw new JsonWrapper.Error.INVALID_NODE_TYPE("This entry isn't part of an object");
		 
		 return (string) this.key;
	}
	
	public uint get_index() throws JsonWrapper.Error {
		 if(!this.key.holds(typeof(uint))) throw new JsonWrapper.Error.INVALID_NODE_TYPE("This entry isn't part of an array");
		 
		 return (uint) this.key;
	}
}
