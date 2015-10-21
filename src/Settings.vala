using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Settings : GLib.Object {
	const string PREFIX = "de.wordclock.";
	
	private GLib.SettingsSchemaSource sss;
	private TreeMap<GLib.Object,GLib.Settings> settings = new TreeMap<GLib.Object,GLib.Settings>();
	
	public TreeMultiMap<string,string> settings_paths { get; set; default = new TreeMultiMap<string,string>(); }
	
	public Settings() {
		try {
			this.sss = new GLib.SettingsSchemaSource.from_directory ("schemas/", GLib.SettingsSchemaSource.get_default(), false);
		} catch( Error e ) {
			stderr.printf("%s\n", e.message);
		}
		
		GLib.SettingsSchema sschema = sss.lookup (PREFIX+"settings", false);
				
		var settings = new GLib.Settings.full (sschema, null, null);
		
		settings.bind_with_mapping(
			"settings-paths",
			this,
			"settings_paths",
			GLib.SettingsBindFlags.DEFAULT,
			get_mapping,
			set_mapping,
			null, null
		);
	}
	
	private static bool get_mapping( GLib.Value value, GLib.Variant variant, void* user_data ) {
		TreeMultiMap<string,string> settings_paths = new TreeMultiMap<string,string>();
		
		for(int i=0;i<variant.n_children();i++) {
			Variant v = variant.get_child_value(i);
			string key;
			v.get_child(0, "s", out key);
			string[] vals = v.get_child_value(1).get_objv();
			foreach(string val in vals) {
				settings_paths.@set(key,val);
			}
		}
		
		value.set_object( settings_paths );
		
		return true;
	}
	private static GLib.Variant set_mapping( GLib.Value value, GLib.VariantType expected_type, void* user_data ) {
		TreeMultiMap<string,string> settings_paths = (TreeMultiMap<string,string>) value.get_object();
		
		Variant[] vars = {};
		foreach(string key in settings_paths.get_keys()) {
			Variant[] vals = {};
			foreach(string val in settings_paths.@get(key)) {
				vals += new Variant.object_path(val);
			}
			vars += new Variant.dict_entry(new Variant.string(key), new Variant.array( VariantType.OBJECT_PATH, vals ) );
		}
		
		return new Variant.array( new VariantType.dict_entry( VariantType.STRING, new VariantType.array( VariantType.OBJECT_PATH ) ), vars );
	}
	
	public bool add_object( GLib.Object obj, string schema, string settings_name, GLib.SettingsBindFlags bind = GLib.SettingsBindFlags.DEFAULT ) {
		settings_name.canon("abcdefghijklmnopqrstuvwxyz-",'-');
		
		GLib.SettingsSchema sschema = sss.lookup (PREFIX+schema, false);
		if (sschema == null) {
			return false;
		}
		string path = "/"+(PREFIX+schema).replace(".","/")+"/"+settings_name+"/";
		var settings = new GLib.Settings.full (sschema, null, path);
		
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
		
		this.settings_paths.@set(schema,path.substring(0,path.length-1));
		this.notify_property("settings_paths");
		
		return true;
	}
	
	public void remove_object( GLib.Object obj ) {
		foreach(ParamSpec p in obj.get_class().list_properties()) {
			GLib.Settings.unbind(obj, p.name);
		}
		
		this.settings.unset(obj);
	}
}
