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
		
		OWMWeatherInfo? weather = (Main.settings.objects["weather"] as OWMWeatherProvider).get_weather();
		if(weather==null) return;
		
		this.message = new Cancellable();
		
		string str = template;
		str = str.replace("{TEMP}", "%.1f°C".printf(weather.main.temp));
		str = str.replace("{DESCRIPTION}",weather.weather.size > 0 ? weather.weather[0].description : "");
		str = str.replace("{CITY}", weather.name);
		
		yield (Main.settings.objects["message"] as MessageOverlay).message(str, MessageType.INFO, 1, this.message);
		this.message = null;
	}
	
}
