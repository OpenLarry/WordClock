using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.ClockWiring : GLib.Object {
	public abstract Color[,] get_matrix( Color[,] leds );
	public abstract Color[] get_dots( Color[,] leds );
	public abstract Color[] get_backlight( Color[,] leds );
}
