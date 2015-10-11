using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.LedDriver : GLib.Object {
	public abstract int start( FrameRenderer renderer );
	public abstract void set_fps( uint8 fps );
}
