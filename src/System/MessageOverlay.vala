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
	
	public Color background_color {
		get { return this.background_renderer.color; }
		set { this.background_renderer.color = value; }
	}
	
	public int x_speed {
		get { return this.text_renderer.x_speed; }
		set { this.text_renderer.x_speed = value; }
	}
	public int y_offset {
		get { return this.text_renderer.y_offset; }
		set { this.text_renderer.y_offset = value; }
	}
	public string font {
		get { return this.text_renderer.font; }
		set { this.text_renderer.font = value; }
	}
	public bool antialias {
		get { return this.text_renderer.antialias; }
		set { this.text_renderer.antialias = value; }
	}
	public bool hint_metrics {
		get { return this.text_renderer.hint_metrics; }
		set { this.text_renderer.hint_metrics = value; }
	}
	public uint8 hint_style {
		get { return this.text_renderer.hint_style; }
		set { this.text_renderer.hint_style = value; }
	}
	public float letter_spacing {
		get { return this.text_renderer.letter_spacing; }
		set { this.text_renderer.letter_spacing = value; }
	}
	
	
	protected ClockRenderer renderer;
	protected TextRenderer text_renderer = new TextRenderer();
	protected ColorRenderer background_renderer = new ColorRenderer();
	
	construct {
		this.text_renderer.markup = true;
		this.text_renderer.time_format = false;
	}
	
	public MessageOverlay( ClockRenderer renderer ) {
		this.renderer = renderer;
	}
	
	public async ClockRenderer.ReturnReason message( string str, MessageType type = MessageType.INFO, int count = 1, Cancellable? cancellable = null ) {
		debug("Display message: %s (%s)", str, type.to_string());
		
		this.text_renderer.reset();
		this.text_renderer.text = str;
		this.text_renderer.count = count;
		
		switch(type) {
			case MessageType.ERROR:
				this.text_renderer.color  = this.error_color;
			break;
			case MessageType.WARNING:
				this.text_renderer.color  = this.warning_color;
			break;
			case MessageType.INFO:
				this.text_renderer.color  = this.info_color;
			break;
			case MessageType.SUCCESS:
				this.text_renderer.color  = this.success_color;
			break;
		}
		
		ClockRenderer.ReturnReason reason = yield this.renderer.overwrite( { this.background_renderer, this.text_renderer }, { this.background_renderer }, { this.background_renderer }, cancellable );
		
		debug("Display message finished"); 
		return reason;
	}
	
	public Cancellable error( string str, int count = 1, Cancellable cancellable = new Cancellable() ) {
		this.message.begin( str, MessageType.ERROR, count, cancellable );
		return cancellable;
	}
	
	public Cancellable warning( string str, int count = 1, Cancellable cancellable = new Cancellable() ) {
		this.message.begin( str, MessageType.WARNING, count, cancellable );
		return cancellable;
	}
	
	public Cancellable info( string str, int count = 1, Cancellable cancellable = new Cancellable() ) {
		this.message.begin( str, MessageType.INFO, count, cancellable );
		return cancellable;
	}
	
	public Cancellable success( string str, int count = 1, Cancellable cancellable = new Cancellable() ) {
		this.message.begin( str, MessageType.SUCCESS, count, cancellable );
		return cancellable;
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
