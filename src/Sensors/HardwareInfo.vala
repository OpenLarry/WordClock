using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.HardwareInfo : GLib.Object, Jsonable {
	public JsonableTreeMap<Lradc> lradcs { get; set; default = new JsonableTreeMap<Lradc>(); }
	public JsonableTreeMap<Gpio> gpios { get; set; default = new JsonableTreeMap<Gpio>(); }
	
	public string iwconfig {
		owned get { 
			string output;
			try{
				Process.spawn_command_line_sync("iwconfig wlan0", out output);
			}catch( Error e ) {
				output = e.message;
			}
			return output; 
		}
	}
}
