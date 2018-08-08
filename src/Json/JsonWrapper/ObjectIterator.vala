using JsonWrapper;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class JsonWrapper.ObjectIterator : GLib.Object, Iterator {
	private Node json;
	private List<unowned string> members;
	private unowned List<unowned string> next_member;
	
	internal ObjectIterator( Node json ) {
		this.json = json;
		this.members = this.json.node.get_object().get_members();
		this.reset();
	}
	
	public Entry? next_value() throws JsonWrapper.Error {
		if( this.next_member == null || this.next_member.data == null ) return null;
		
		Entry entry = new Entry( this.next_member.data, this.json[this.next_member.data] );
		this.next_member = this.next_member.next;
		return entry;
	}
	
	public void reset() {
		this.next_member = this.members;
	}
}
