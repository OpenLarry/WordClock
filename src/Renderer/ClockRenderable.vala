using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.ClockRenderable : GLib.Object {
	public virtual void activate() {}
	public virtual uint8[] get_fps_range() {
		return {1,uint8.MAX};
	}
}
