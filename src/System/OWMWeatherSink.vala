using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.OWMWeatherSink : GLib.Object, Jsonable, SignalSink {
	public void action() {
		OWMWeatherInfo? weather = Main.weather.get_weather();
		if(weather==null) return;
		
		Main.message.info( "%s: %.1f°C %s".printf( weather.name, weather.main.temp, weather.weather.size > 0 ? weather.weather[0].description : "") );
	}
	
}
