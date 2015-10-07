using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.FrameRenderer : GLib.Object {
	public abstract bool render( Color[,] leds );
}
