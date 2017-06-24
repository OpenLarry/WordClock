using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.StringChooser : GLib.Object {
	private string[] strings;
	private string? message;
	private Cancellable? cancellable = null;
	
	private int pos = 0;
	
	private static bool running = false;
	
	public StringChooser( string[] strings, string? message = null ) {
		this.strings = strings;
		this.message = message;
	}

	public async int choose() {
		if(running) return -2;
		running = true;
		
		debug("Start StringChooser");
		
		try{
			if(this.message != null) {
				yield (Main.settings.objects["message"] as MessageOverlay).message(this.message, MessageType.INFO, 1, this.cancellable);
			}
			
			if(this.strings.length == 0) return -1;
			
			while(running) {
				this.cancellable = new Cancellable();
				ClockRenderer.ReturnReason ret = yield (Main.settings.objects["message"] as MessageOverlay).message(this.strings[this.pos], MessageType.INFO, -1, this.cancellable);
				if(ret == ClockRenderer.ReturnReason.REPLACED) this.action(StringChooserAction.ABORT);
			}
			
			return this.pos;
		} finally {
			this.cancellable = null;
			running = false;
			debug("End StringChooser");
		}
	}
	
	public void action( StringChooserAction action ) {
		if(this.cancellable == null) return;
		
		switch(action) {
			case StringChooserAction.UP:
				if(this.pos == this.strings.length - 1) this.pos = 0;
				else this.pos = (this.pos + 1);
				break;
			case StringChooserAction.DOWN:
				if(this.pos == 0) this.pos = this.strings.length - 1;
				else this.pos = (this.pos - 1);
				break;
			case StringChooserAction.SELECT:
				running = false;
				break;
			case StringChooserAction.ABORT:
				running = false;
				this.pos = -1;
				break;
		}
		
		this.cancellable.cancel();
	}
}

public enum WordClock.StringChooserAction {
	UP,
	DOWN,
	SELECT,
	ABORT
}
