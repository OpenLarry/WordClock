using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.OWMWeatherRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer {
	const string ICON_PATH = "weather/%s.png";
	
	private ImageRenderer renderer = new ImageRenderer();
	
	public bool render_matrix( Color[,] matrix ) {
		OWMWeatherInfo? info = Main.weather.get_weather();
		
		if(info==null || info.weather.size == 0) return true;
		
		renderer.path = ICON_PATH.printf(info.weather[0].icon);
		
		return renderer.render_matrix(matrix);
	}
}
