using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.SystemSensor : GLib.Object, Jsonable {
	public signal void update();
}
