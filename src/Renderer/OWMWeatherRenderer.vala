using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.OWMWeatherRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer {
	public string icon_path { get; set; default = "/usr/share/wordclock/weather/%s.png"; }
	
	private ImageRenderer renderer = new ImageRenderer();
	
	public bool render_matrix( Color[,] matrix ) {
		JsonWrapper.Node? info = (Main.settings.objects["weather"] as OWMWeatherProvider).get_weather();
		
		if(info==null) return true;
		
		try {
			renderer.path = icon_path.printf(info["weather"][0]["icon"].to_string());
		
			return renderer.render_matrix(matrix);
		} catch ( Error e ) {
			return true;
		}
	}
}
