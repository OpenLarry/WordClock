using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.BacklightRenderer : GLib.Object, ClockRenderable {
	public abstract bool render_backlight( Color[] leds );
}
