using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.OWMWeatherSink : GLib.Object, Jsonable, SignalSink {
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
		yield (Main.settings.objects["message"] as MessageOverlay).message( "%s: %.1f°C %s".printf( weather.name, weather.main.temp, weather.weather.size > 0 ? weather.weather[0].description : ""), MessageType.INFO, 1, this.message);
		this.message = null;
	}
	
}
