using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.SignalSource : GLib.Object {
	public signal bool action( string name );
}
