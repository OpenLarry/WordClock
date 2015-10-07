using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.ClockWiring : GLib.Object {
	public abstract Color[,] getMatrix( Color[,] leds );
	public abstract Color[] getMinutes( Color[,] leds );
	public abstract Color[] getSeconds( Color[,] leds );
}
