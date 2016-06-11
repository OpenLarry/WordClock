using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.OWMWeatherSink : GLib.Object, Jsonable, SignalSink {
	public void action() {
		OWMWeatherInfo? weather = (Main.settings.objects["weather"] as OWMWeatherProvider).get_weather();
		if(weather==null) return;
		
		(Main.settings.objects["message"] as MessageOverlay).info( "%s: %.1f°C %s".printf( weather.name, weather.main.temp, weather.weather.size > 0 ? weather.weather[0].description : "") );
	}
	
}
