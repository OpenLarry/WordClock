using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.DotsRenderer : GLib.Object, ClockRenderable {
	public abstract bool render_dots( Color[] leds );
}
