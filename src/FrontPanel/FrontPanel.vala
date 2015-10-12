using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.FrontPanel : GLib.Object {
	public class WordPosition {
		public int x;
		public int y;
		public int length;
	}
	
	public abstract HashSet<WordPosition> getTime( uint8 hour, uint8 minute );
}
