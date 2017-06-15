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
		yield (Main.settings.objects["message"] as MessageOverlay).message(@"WordClock $(Version.GIT_DESCRIBE)  IP: $(systeminfo.ip)  Host: $(systeminfo.hostname)  WLAN: $(systeminfo.wlan)  Kernel: $(systeminfo.kernel)", MessageType.INFO, 1, this.message);
		this.message = null;
	}
}
