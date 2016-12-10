using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.HardwareInfo : GLib.Object, Jsonable {
	public JsonableTreeMap<Lradc> lradcs { get; set; default = new JsonableTreeMap<Lradc>(); }
	public JsonableTreeMap<Gpio> gpios { get; set; default = new JsonableTreeMap<Gpio>(); }
	public JsonableTreeMap<SystemSensor> system { get; set; default = new JsonableTreeMap<SystemSensor>(); }
}
