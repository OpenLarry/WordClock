using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.StringInput : GLib.Object {
	private string? message;
	private Cancellable? cancellable = null;
	
	private string? string = null;
	private bool blink = false;
	
	private static bool running = false;
	private const string SYMBOLS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!?$%&#@/\\\"'*+-=_.,:;()[]{}<>|^`~ ";
	
	private TextRenderer text_renderer = new TextRenderer();
	private ColorRenderer background = new ColorRenderer();
	
	construct {
		text_renderer.time_format = false;
		text_renderer.x_speed = 0;
		text_renderer.x_offset = -11;
		text_renderer.letter_spacing = 0;
		text_renderer.markup = true;
	}
	
	public StringInput( string? message = null ) {
		this.message = message;
	}

	public async string? read() {
		if(running) return null;
		running = true;
		
		debug("Start StringInput");
		
		try {
			if(this.message != null) {
				yield Main.settings.get<MessageOverlay>().message(this.message, MessageType.INFO, 1, this.cancellable);
			}
			
			this.string = "A";
			
			this.update_text();
			text_renderer.color = Main.settings.get<MessageOverlay>().info_color;
			text_renderer.font = Main.settings.get<MessageOverlay>().font;
			
			background.color = Main.settings.get<MessageOverlay>().background_color;
			
			// letter blink timer
			Timeout.add(500, () => {
				if(!running) return Source.REMOVE;
				
				this.blink = !this.blink;
				this.update_text();
				
				return Source.CONTINUE;
			});
			
			this.cancellable = new Cancellable();
			ClockRenderer.ReturnReason ret = yield Main.settings.get<ClockRenderer>().overwrite( { background, text_renderer }, { background }, { background }, this.cancellable);
			if(ret == ClockRenderer.ReturnReason.REPLACED) this.action(StringInputAction.ABORT);
			
			return this.string;
		} finally {
			this.cancellable = null;
			running = false;
			debug("End StringInput");
		}
	}
	
	private void update_text() {
		if(this.string == null) return;
		
		this.text_renderer.text = TextRenderer.escape(this.string[0:-1]) + "<span color=\"#" + (this.blink ? "888888" : "ffffff") + "\">" + TextRenderer.escape(this.string[this.string.length-1].to_string()) + "</span>";
	}
	
	public void action( StringInputAction action ) {
		if(this.cancellable == null) return;
		
		switch(action) {
			case StringInputAction.UP:
			case StringInputAction.DOWN:
				int index = SYMBOLS.index_of(this.string.substring(-1));
				if(action == StringInputAction.UP) index++;
				if(action == StringInputAction.DOWN) index--;
				if(index < 0) index = SYMBOLS.length-1;
				if(index >= SYMBOLS.length) index = 0;
				
				this.string = this.string.slice(0,-1) + SYMBOLS.substring(index,1);
				break;
			case StringInputAction.UPPERCASE:
				this.string = this.string.slice(0,-1) + "A";
				break;
			case StringInputAction.LOWERCASE:
				this.string = this.string.slice(0,-1) + "a";
				break;
			case StringInputAction.NUMBERS:
				this.string = this.string.slice(0,-1) + "0";
				break;
			case StringInputAction.SPECIAL:
				this.string = this.string.slice(0,-1) + "!";
				break;
			case StringInputAction.SELECT:
				this.cancellable.cancel();
				return;
			case StringInputAction.NEXT:
				this.string += this.string.substring(-1);
				break;
			case StringInputAction.PREV:
				if(this.string.length == 1) {
					this.action(StringInputAction.ABORT);
					return;
				}else{
					this.string = this.string.slice(0,-1);
				}
				break;
			case StringInputAction.ABORT:
				this.string = null;
				this.cancellable.cancel();
				return;
		}
		
		this.update_text();
	}
}

public enum WordClock.StringInputAction {
	UP,
	DOWN,
	PREV,
	NEXT,
	SELECT,
	ABORT,
	UPPERCASE,
	LOWERCASE,
	NUMBERS,
	SPECIAL
}
