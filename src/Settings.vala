using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Settings : GLib.Object, Json.Serializable, Serializable {
	const string PREFIX = "de.wordclock";
	
	private GLib.SettingsSchemaSource sss;
	private TreeMap<GLib.Object,GLib.Settings> settings = new TreeMap<GLib.Object,GLib.Settings>();
	
	public TreeSet<string> settings_paths { get; set; default = new TreeSet<string>(); }
	
	private Regex class_regex;
	
	public Settings() {
		try {
			this.sss = new GLib.SettingsSchemaSource.from_directory ("schemas/", GLib.SettingsSchemaSource.get_default(), false);
			
			this.class_regex = new Regex("([A-Z][a-z]*)");
		} catch( Error e ) {
			stderr.printf("%s\n", e.message);
		}
		
		GLib.SettingsSchema sschema = sss.lookup (PREFIX+".settings", false);
				
		var settings = new GLib.Settings.full (sschema, null, null);
		
		settings.bind_with_mapping(
			"settings-paths",
			this,
			"settings_paths",
			GLib.SettingsBindFlags.DEFAULT,
			(SettingsBindGetMappingShared) VariantMapper.settings_get_mapping,
			(SettingsBindSetMappingShared) VariantMapper.settings_set_mapping,
			null, null
		);
	}
	
	public bool add_object( GLib.Object obj, string? settings_name = null, GLib.SettingsBindFlags bind = GLib.SettingsBindFlags.DEFAULT ) {
		string class_name = obj.get_class().get_type().name().substring(9);
		
		MatchInfo match_info;
		this.class_regex.match(class_name, 0, out match_info);
		
		string[] class_name_parts = {};
		try{
			while(match_info.matches()) {
				class_name_parts += match_info.fetch(0);
				match_info.next();
			}
		} catch( Error e ) {
			stderr.printf("%s\n", e.message);
		}
		
		string schema_name = PREFIX;
		for(int i=(class_name_parts.length-1);i>=0;i--) {
			schema_name += "."+class_name_parts[i].down();
		}
		
		string? path = null;
		if(settings_name != null) {
			path = "/"+schema_name.replace(".","/")+"/"+settings_name+"/";
		}
		
		settings_name.canon("abcdefghijklmnopqrstuvwxyz-",'-');
		
		GLib.SettingsSchema sschema = sss.lookup (schema_name, false);
		if (sschema == null) {
			return false;
		}
		
		var settings = new GLib.Settings.full (sschema, null, path);
		
		foreach(ParamSpec p in obj.get_class().list_properties()) {
			var name = p.name;
			name.canon("abcdefghijklmnopqrstuvwxyz-",'-');
			if(!sschema.has_key(name)) continue;
			
			if(p.value_type.is_a(typeof(Color))) {
				settings.bind_with_mapping(name, obj, p.name, bind,(SettingsBindGetMappingShared) VariantMapper.color_get_mapping,(SettingsBindSetMappingShared) VariantMapper.color_set_mapping, null, null);
			}else{
				settings.bind(name, obj, p.name, bind);
			}
		}
		
		this.settings.@set(obj, settings);
		
		if(path!=null) this.settings_paths.add(path.substring(0,path.length-1));
		this.notify_property("settings_paths");
		
		return true;
	}
	
	public void remove_object( GLib.Object obj ) {
		foreach(ParamSpec p in obj.get_class().list_properties()) {
			GLib.Settings.unbind(obj, p.name);
		}
		
		this.settings.unset(obj);
	}
	
	// workaround for multiple inheritance
	// https://wiki.gnome.org/Projects/Vala/Tutorial#Mixins_and_Multiple_Inheritance
	public Json.Node Json.Serializable.serialize_property(string property_name, Value value, ParamSpec pspec) { return Serializable.serialize_property(this,property_name,value,pspec); }
	public bool Json.Serializable.deserialize_property(string property_name, out Value value, ParamSpec pspec, Json.Node property_node) { return Serializable.deserialize_property(this,property_name,out value,pspec,property_node); 	}
	public unowned ParamSpec Json.Serializable.find_property(string name) { return Serializable.find_property(this,name); }
}
