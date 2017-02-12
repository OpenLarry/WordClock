using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.InfoSink : GLib.Object, Jsonable, SignalSink {
	const string INTERFACE = "wlan0";
	
	private uint? message_id = null;
	
	public void action () {
		// stop current message
		if(this.message_id != null) {
			if((Main.settings.objects["message"] as MessageOverlay).stop(this.message_id)) {
				this.message_id = null;
				return;
			}
		}
		
		SystemInfo systeminfo = new SystemInfo();
		this.message_id = (Main.settings.objects["message"] as MessageOverlay).info(@"WordClock $(Version.GIT_DESCRIBE)  IP: $(systeminfo.ip)  Host: $(systeminfo.hostname)  WLAN: $(systeminfo.wlan)  Kernel: $(systeminfo.kernel)");
	}
}
