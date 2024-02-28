using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.OWMWeatherSink : GLib.Object, Jsonable, SignalSink {
	public string template { get; set; default = "{TEMP} {DESCRIPTION} - <span color=\"#ffff00\">{CITY}</span>"; }
	
	private Cancellable? message = null;
	
	public void action() {
		this.async_action.begin();
	}
	
	public async void async_action() {
		// stop current message
		if(this.message != null) {
			this.message.cancel();
			return;
		}
		JsonWrapper.Node? weather = Main.settings.get<OWMWeatherProvider>().get_weather();
		if(weather==null) return;
		
		this.message = new Cancellable();
		
		try {
			string str = template;
			str = str.replace("{TEMP}", "%.1f°C".printf((double)weather["main"]["temp"].get_typed_value(typeof(double))));
			str = str.replace("{DESCRIPTION}",weather["weather"][0]["description"].to_string());
			str = str.replace("{CITY}", weather["name"].to_string());
			
			yield Main.settings.get<MessageOverlay>().message(str, MessageType.INFO, 1, this.message);
			this.message = null;
		} catch ( Error e ) {
			warning(e.message);
		}
	}
	
}
