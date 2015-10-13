using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Settings : GLib.Object {
	private GLib.SettingsSchemaSource sss;
	
	public Settings(SecondsRenderer r) {
		try {
			this.sss = new GLib.SettingsSchemaSource.from_directory ("schemas/", GLib.SettingsSchemaSource.get_default(), false);
		} catch( Error e ) {
			stderr.printf("%s\n", e.message);
		}
	}
	
	public void add_object( SettingsBindable obj, string name ) {
		obj.bind_settings( this.sss, name );
	}
	
	public void remove_object( SettingsBindable obj ) {
		obj.unbind_settings( );
	}
}
