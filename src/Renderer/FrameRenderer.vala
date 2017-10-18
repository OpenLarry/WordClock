using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.FrameRenderer : GLib.Object {
	public abstract void set_leds( Color[,] leds );
	public abstract void render( );
}
