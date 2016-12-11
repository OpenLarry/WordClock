using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.OWMWeatherSink : GLib.Object, Jsonable, SignalSink {
	private uint? message_id = null;
	
	public void action() {
		// stop current message
		if(this.message_id != null) {
			if((Main.settings.objects["message"] as MessageOverlay).stop(this.message_id)) {
				this.message_id = null;
				return;
			}
		}
		
		OWMWeatherInfo? weather = (Main.settings.objects["weather"] as OWMWeatherProvider).get_weather();
		if(weather==null) return;
		
		this.message_id = (Main.settings.objects["message"] as MessageOverlay).info( "%s: %.1f°C %s".printf( weather.name, weather.main.temp, weather.weather.size > 0 ? weather.weather[0].description : "") );
	}
	
}
