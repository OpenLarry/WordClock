using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.Font : GLib.Object {
	public abstract uint8[] get_bitmaps();
	public abstract uint16[,] get_descriptors();
	public abstract uint8 get_height();
	public abstract uint8 get_offset();
	public abstract uint8 get_character_spacing();
}
