using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.MatrixRenderer : GLib.Object, ClockRenderable {
	public abstract bool render_matrix( Color[,] leds );
}
