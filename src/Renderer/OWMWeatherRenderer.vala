using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.OWMWeatherRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer {
	public string icon_path { get; set; default = "/usr/share/wordclock/weather/%s.png"; }
	
	private ImageRenderer renderer = new ImageRenderer();
	
	public bool render_matrix( Color[,] matrix ) {
		OWMWeatherInfo? info = (Main.settings.objects["weather"] as OWMWeatherProvider).get_weather();
		
		if(info==null || info.weather.size == 0) return true;
		
		renderer.path = icon_path.printf(info.weather[0].icon);
		
		return renderer.render_matrix(matrix);
	}
}
