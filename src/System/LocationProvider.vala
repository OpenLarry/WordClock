using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.LocationProvider : GLib.Object, Jsonable {
	public signal void update();
	public abstract LocationInfo? get_location();
}

// container class
public class WordClock.LocationInfo : GLib.Object, Jsonable {
	public int accuracy { get; set; default = 0; }
	public double lat { get; set; default = 0; }
	public double lng { get; set; default = 0; }
}
