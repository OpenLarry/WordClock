using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.WpsPbcSink : GLib.Object, Jsonable, SignalSink {
	private static Cancellable cancellable = null;
	
	public void action () {
		this.async_action.begin();
	}
	
	public async void async_action() {
		if(cancellable != null) {
			debug("Cancel wps");
			cancellable.cancel();
			return;
		}
		cancellable = new Cancellable();
		
		try{
			debug("Starting wps");
			
			Main.settings.get<ImageOverlay>().image.begin("/usr/share/wordclock/wlan_connecting.png", 0, 4, -1, cancellable, (obj,res) => {
				ClockRenderer.ReturnReason reason = Main.settings.get<ImageOverlay>().image.end(res);
				if(reason == ClockRenderer.ReturnReason.REPLACED && cancellable != null) cancellable.cancel();
			});
			
			bool? success = yield Main.settings.get<WirelessNetworks>().wps_pbc( null, cancellable );
			
			if(cancellable.is_cancelled()) {
				// intended
			}else if(success == true) {
				cancellable.cancel();
				info("WPS success");
				Buzzer.beep(100,3000,25);
				Buzzer.beep(400,4000,25);
			}else{
				cancellable.cancel();
				if(success == false) {
					Main.settings.get<MessageOverlay>().error("Error!");
					warning("WPS failed");
				}else{
					Main.settings.get<MessageOverlay>().error("Timeout!");
					warning("WPS timeout");
				}
				Buzzer.beep(200,1000,25);
				Buzzer.pause(200);
				Buzzer.beep(200,1000,25);
			}
			
			debug("Finished wps");
		} catch(Error e) {
			cancellable.cancel();
			Main.settings.get<MessageOverlay>().error("Error!");
			warning(e.message);
			Buzzer.beep(200,1000,25);
			Buzzer.pause(200);
			Buzzer.beep(200,1000,25);
		} finally {
			cancellable = null;
		}
	}
}
