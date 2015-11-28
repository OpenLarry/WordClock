using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.ClockConfiguration : GLib.Object, Jsonable {
	public JsonableArrayList<JsonableString> matrix { get; set; default = new JsonableArrayList<JsonableString>(); }
	public JsonableArrayList<JsonableString> dots { get; set; default = new JsonableArrayList<JsonableString>(); }
	public JsonableArrayList<JsonableString> backlight { get; set; default = new JsonableArrayList<JsonableString>(); }
	
	public ClockConfiguration( JsonableArrayList<JsonableString> matrix, JsonableArrayList<JsonableString> dots, JsonableArrayList<JsonableString> backlight ) {
		this.matrix = matrix;
		this.dots = dots;
		this.backlight = backlight;
	}
}
