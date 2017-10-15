using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.InfoSink : GLib.Object, Jsonable, SignalSink {
	const string INTERFACE = "wlan0";
	
	private Cancellable? message = null;
	
	public void action() {
		this.async_action.begin();
	}
	
	public async void async_action () {
		// stop current message
		if(this.message != null) {
			this.message.cancel();
			return;
		}
		
		SystemInfo systeminfo = new SystemInfo();
		this.message = new Cancellable();
		yield (Main.settings.objects["message"] as MessageOverlay).message(@"WordClock $(Version.GIT_DESCRIBE)  IP: <span color=\"#ffff00\">$(systeminfo.ip)</span>  Host: <span color=\"#ffff00\">$(systeminfo.hostname)</span>  WLAN: <span color=\"#ffff00\">$(systeminfo.wlan)</span>  Kernel: <span color=\"#ffff00\">$(systeminfo.kernel)</span>", MessageType.INFO, 1, this.message);
		this.message = null;
	}
}
