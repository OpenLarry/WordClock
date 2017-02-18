using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public abstract class WordClock.LedDriver : GLib.Object, Jsonable, SystemSensor {
	public uint current_fps { get; protected set; default = 0; }
	protected uint8 fps = 25;
	
	protected GLib.Cancellable? cancellable;
	
	public LedDriver( Cancellable? cancellable = null ) {
		this.cancellable = cancellable;
	}
	public abstract int start( FrameRenderer renderer );
	public abstract void set_fps( uint8 fps );
}
