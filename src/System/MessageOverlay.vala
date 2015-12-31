using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.MessageOverlay : GLib.Object, Jsonable {
	public Color error_color { get; set; default = new Color.from_hsv( 0, 255, 200 ); }
	public Color warning_color { get; set; default = new Color.from_hsv( 60, 255, 200 ); }
	public Color info_color { get; set; default = new Color.from_hsv( 0, 0, 200 ); }
	public Color success_color { get; set; default = new Color.from_hsv( 120, 255, 200 ); }
	public Color background_color { get; set; default = new Color.from_hsv( 0, 0, 0 ); }
	
	protected ClockRenderer renderer;
	protected bool infinite = false;
	
	public MessageOverlay( ClockRenderer renderer ) {
		this.renderer = renderer;
	}
	
	public void message( string str, MessageType type = MessageType.INFO, int count = 1 ) {
		StringRenderer str_renderer = new StringRenderer();
		str_renderer.string = str;
		str_renderer.time_format = false;
		str_renderer.count = count;
		
		if(count < 0) this.infinite = true;
		
		ColorRenderer background = new ColorRenderer();
		background.color = this.background_color;
		
		switch(type) {
			case MessageType.ERROR:
				str_renderer.left_color  = this.error_color;
				str_renderer.right_color = this.error_color;
			break;
			case MessageType.WARNING:
				str_renderer.left_color  = this.warning_color;
				str_renderer.right_color = this.warning_color;
			break;
			case MessageType.INFO:
				str_renderer.left_color  = this.info_color;
				str_renderer.right_color = this.info_color;
			break;
			case MessageType.SUCCESS:
				str_renderer.left_color  = this.success_color;
				str_renderer.right_color = this.success_color;
			break;
		}
		
		this.renderer.set_overwrite( { background, str_renderer }, { background }, { background } );
	}
	
	public void error( string str, int count = 1 ) {
		this.message( str, MessageType.ERROR, count );
	}
	
	public void warning( string str, int count = 1 ) {
		this.message( str, MessageType.WARNING, count );
	}
	
	public void info( string str, int count = 1 ) {
		this.message( str, MessageType.INFO, count );
	}
	
	public void success( string str, int count = 1 ) {
		this.message( str, MessageType.SUCCESS, count );
	}
	
	public void stop() {
		if(this.infinite) {
			this.renderer.set_overwrite( null, null, null );
		}
	}
}

public enum WordClock.MessageType {
	ERROR,
	WARNING,
	INFO,
	SUCCESS
}
