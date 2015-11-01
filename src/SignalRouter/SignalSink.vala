using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.SignalSink : GLib.Object, Jsonable {
	public abstract void action ( int repetition );
}
