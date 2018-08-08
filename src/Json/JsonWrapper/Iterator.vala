using JsonWrapper;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface JsonWrapper.Iterator : GLib.Object {
	public abstract Entry? next_value() throws JsonWrapper.Error;
	public abstract void reset();
}
