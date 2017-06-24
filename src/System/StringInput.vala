using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.StringInput : GLib.Object {
	private string? message;
	private Cancellable? cancellable = null;
	
	private string? string = null;
	
	private static bool running = false;
	private const string SYMBOLS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!?$%&#@/\\\"'*+-=_.,:;()[]{}<>|^`~ ";
	
	public StringInput( string? message = null ) {
		this.message = message;
	}

	public async string? read() {
		if(running) return null;
		running = true;
		
		debug("Start StringInput");
		
		try {
			if(this.message != null) {
				yield (Main.settings.objects["message"] as MessageOverlay).message(this.message, MessageType.INFO, 1, this.cancellable);
			}
			
			this.string = "A";
			
			StringRenderer str_renderer = new StringRenderer();
			str_renderer.time_format = false;
			str_renderer.speed = 0;
			str_renderer.position = -11;
			str_renderer.left_color = (Main.settings.objects["message"] as MessageOverlay).info_color;
			str_renderer.right_color = (Main.settings.objects["message"] as MessageOverlay).info_color;
			
			ColorRenderer background = new ColorRenderer();
			background.color = (Main.settings.objects["message"] as MessageOverlay).background_color;
			
			while(running) {
				str_renderer.string = this.string;
				this.cancellable = new Cancellable();
				ClockRenderer.ReturnReason ret = yield (Main.settings.objects["clockrenderer"] as ClockRenderer).overwrite( { background, str_renderer }, { background }, { background }, this.cancellable);
				if(ret == ClockRenderer.ReturnReason.REPLACED) this.action(StringInputAction.ABORT);
			}
			
			return this.string;
		} finally {
			this.cancellable = null;
			running = false;
			debug("End StringInput");
		}
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
				running = false;
				break;
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
				running = false;
				this.string = null;
				break;
		}
		
		this.cancellable.cancel();
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
