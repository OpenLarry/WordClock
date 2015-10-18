using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Settings : GLib.Object {
	const string PREFIX = "de.wordclock.";
	
	private GLib.SettingsSchemaSource sss;
	private TreeMap<string,GLib.Settings> settings = new TreeMap<string,GLib.Settings>();
	
	public Settings(SecondsRenderer r) {
		try {
			this.sss = new GLib.SettingsSchemaSource.from_directory ("schemas/", GLib.SettingsSchemaSource.get_default(), false);
		} catch( Error e ) {
			stderr.printf("%s\n", e.message);
		}
	}
	
	public void add_object( GLib.Object obj, string schema, string settings_name ) {
		settings_name.canon("abcdefghijklmnopqrstuvwxyz-",'-');
		
		GLib.SettingsSchema sschema = sss.lookup (PREFIX+schema, false);
		if (sss.lookup == null) {
			stderr.printf ("ID not found.");
			return;
		}
		
		var settings = new GLib.Settings.full (sschema, null, "/"+schema.replace(".","/")+"/"+settings_name+"/");
		
		foreach(ParamSpec p in obj.get_class().list_properties()) {
			var name = p.name;
			name.canon("abcdefghijklmnopqrstuvwxyz-",'-');
			
			if(p.value_type.is_a(typeof(Color))) {
				settings.bind_with_mapping(name, obj, p.name, GLib.SettingsBindFlags.DEFAULT,(SettingsBindGetMappingShared) Color.get_mapping,(SettingsBindSetMappingShared) Color.set_mapping, null, null);
			}else{
				settings.bind(name, obj, p.name, GLib.SettingsBindFlags.DEFAULT);
			}
		}
		
		this.settings.@set("/"+schema.replace(".","/")+"/"+settings_name+"/", settings);
	}
	
	public void remove_object( GLib.Object obj ) {
		//obj.unbind_settings( );
	}
}
