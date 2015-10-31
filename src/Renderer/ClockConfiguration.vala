using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.ClockConfiguration : GLib.Object, Jsonable {
	public string matrix { get; set; default = ""; }
	public string dots { get; set; default = ""; }
	public string backlight { get; set; default = ""; }
	
	public ClockConfiguration( string matrix, string dots, string backlight ) {
		this.matrix = matrix;
		this.dots = dots;
		this.backlight = backlight;
	}
}
