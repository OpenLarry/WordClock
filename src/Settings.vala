using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Settings : GLib.Object {
	const string PREFIX = "de.wordclock.";
	
	private GLib.SettingsSchemaSource sss;
	private TreeMap<GLib.Object,GLib.Settings> settings = new TreeMap<GLib.Object,GLib.Settings>();
	
	public Settings() {
		try {
			this.sss = new GLib.SettingsSchemaSource.from_directory ("schemas/", GLib.SettingsSchemaSource.get_default(), false);
		} catch( Error e ) {
			stderr.printf("%s\n", e.message);
		}
	}
	
	public bool add_object( GLib.Object obj, string schema, string settings_name, GLib.SettingsBindFlags bind = GLib.SettingsBindFlags.DEFAULT ) {
		settings_name.canon("abcdefghijklmnopqrstuvwxyz-",'-');
		
		GLib.SettingsSchema sschema = sss.lookup (PREFIX+schema, false);
		if (sschema == null) {
			return false;
		}
		
		var settings = new GLib.Settings.full (sschema, null, "/"+(PREFIX+schema).replace(".","/")+"/"+settings_name+"/");
		
		foreach(ParamSpec p in obj.get_class().list_properties()) {
			var name = p.name;
			name.canon("abcdefghijklmnopqrstuvwxyz-",'-');
			if(!sschema.has_key(name)) continue;
			
			if(p.value_type.is_a(typeof(Color))) {
				settings.bind_with_mapping(name, obj, p.name, bind,(SettingsBindGetMappingShared) Color.get_mapping,(SettingsBindSetMappingShared) Color.set_mapping, null, null);
			}else{
				settings.bind(name, obj, p.name, bind);
			}
		}
		
		this.settings.@set(obj, settings);
		
		return true;
	}
	
	public void remove_object( GLib.Object obj ) {
		foreach(ParamSpec p in obj.get_class().list_properties()) {
			GLib.Settings.unbind(obj, p.name);
		}
		
		this.settings.unset(obj);
	}
}
