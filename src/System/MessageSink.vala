using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.MessageSink : GLib.Object, Jsonable, SignalSink {
	public string text { get; set; default = "Your message!"; }
	public uint count { get; set; default = 1; }
	public string message_type { get; set; default = "INFO"; }
	
	public void action () {
		(Main.settings.objects["message"] as MessageOverlay).message(this.text, MessageType.from_string( this.message_type ), (int) this.count.clamp(1,int.MAX));
	}
}
