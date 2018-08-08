using JsonWrapper;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class JsonWrapper.ArrayIterator : GLib.Object, Iterator {
	private Node json;
	private uint size;
	private uint next_element;
	
	internal ArrayIterator( Node json ) {
		this.json = json;
		this.size = this.json.length;
		this.reset();
	}
	
	public Entry? next_value() throws JsonWrapper.Error {
		if( this.next_element >= this.size ) return null;
		
		Entry entry = new Entry( this.next_element, this.json[this.next_element] );
		this.next_element++;
		return entry;
	}
	
	public void reset() {
		this.next_element = 0;
	}
}
