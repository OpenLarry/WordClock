using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.JsonModifierSink : GLib.Object, Jsonable, SignalSink {
	public JsonableArrayList<string> settings { get; set; default = new JsonableArrayList<string>(); }
	public string path { get; set; default = ""; }
	public bool cyclic { get; set; default = false; }
	
	public void action(int repetition) {
		try {
			string json = Main.settings.get_json( this.path );
			int index = this.settings.index_of(json);
			if(index >= 0) {
				index = (index+1);
			}else{
				index = 0;
			}
			
			if(index >= this.settings.size) {
				if(this.cyclic) {
					index = 0;
				}else{
					index = this.settings.size-1;
				}
			}
			
			Main.settings.set_json( this.settings[index], this.path );
			Main.settings.save();
		} catch( Error e ) {
			stderr.printf("Error: %s\n", e.message);
		}
	}
}
