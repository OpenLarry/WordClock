using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.Wiring : GLib.Object {
	public abstract uint8*[,,] getMatrix( uint8[,,] leds );
	public abstract uint8*[,] getMinutes( uint8[,,] leds );
	public abstract uint8*[,] getSeconds( uint8[,,] leds );
}
