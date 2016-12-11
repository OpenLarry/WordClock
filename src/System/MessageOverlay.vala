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
	public uint8 speed { get; set; default = 15; }
	public uint8 add_spacing { get; set; default = 1; }
	public string font_name { get; set; default = "WordClockMicrosoftSansSerifFont"; }
	
	protected ClockRenderer renderer;
	
	public MessageOverlay( ClockRenderer renderer ) {
		this.renderer = renderer;
	}
	
	public uint message( string str, MessageType type = MessageType.INFO, int count = 1 ) {
		StringRenderer str_renderer = new StringRenderer();
		str_renderer.string = str;
		str_renderer.time_format = false;
		str_renderer.count = count;
		str_renderer.speed = this.speed;
		str_renderer.add_spacing = this.add_spacing;
		str_renderer.font_name = this.font_name;
		
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
		
		return this.renderer.set_overwrite( { background, str_renderer }, { background }, { background } );
	}
	
	public uint error( string str, int count = 1 ) {
		return this.message( str, MessageType.ERROR, count );
	}
	
	public uint warning( string str, int count = 1 ) {
		return this.message( str, MessageType.WARNING, count );
	}
	
	public uint info( string str, int count = 1 ) {
		return this.message( str, MessageType.INFO, count );
	}
	
	public uint success( string str, int count = 1 ) {
		return this.message( str, MessageType.SUCCESS, count );
	}
	
	public bool stop(uint id) {
		return this.renderer.reset_overwrite(id);
	}
}

public enum WordClock.MessageType {
	ERROR,
	WARNING,
	INFO,
	SUCCESS;
	
	public static MessageType from_string( string s ) {
		switch(s) {
			case "ERROR":
				return ERROR;
			case "WARNING":
				return WARNING;
			case "INFO":
			default:
				return INFO;
			case "SUCCESS":
				return SUCCESS;
		}
	}
}
