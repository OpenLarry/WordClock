using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.FrontPanel : GLib.Object {
	public abstract uint8[,] getTime( uint8 hour, uint8 minute );
}
