using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Settings : GLib.Object, Json.Serializable {
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
			get_mapping,
			set_mapping,
			null, null
		);
	}
	
	private static bool get_mapping( GLib.Value value, GLib.Variant variant, void* user_data ) {
		TreeSet<string> settings_paths = new TreeSet<string>();
		
		for(int i=0;i<variant.n_children();i++) {
			string path;
			variant.get_child(i, "o", out path);
			settings_paths.add(path);
		}
		
		value.set_object( settings_paths );
		
		return true;
	}
	private static GLib.Variant set_mapping( GLib.Value value, GLib.VariantType expected_type, void* user_data ) {
		TreeSet<string> settings_paths = (TreeSet<string>) value.get_object();
		
		Variant[] paths = {};
		foreach(string path in settings_paths) {
			paths += new Variant.object_path(path);
		}
		
		return new Variant.array( VariantType.OBJECT_PATH, paths );
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
				settings.bind_with_mapping(name, obj, p.name, bind,(SettingsBindGetMappingShared) Color.get_mapping,(SettingsBindSetMappingShared) Color.set_mapping, null, null);
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
	
	
	public Json.Node serialize_property(string property_name, Value value, ParamSpec pspec) {
		if(pspec.value_type.is_a(typeof(Set))) {
			Set<string> set = (Set<string>) value.get_object();
			
			var array = new Json.Array();
			
			foreach(string val in set) {
				array.add_string_element(val);
			}
			
			var root_node = new Json.Node( Json.NodeType.ARRAY );
			root_node.set_array(array);
			
			return root_node;
		}else{
			return this.default_serialize_property( property_name, value, pspec );
		}
	}
	public bool deserialize_property(string property_name, out Value value, ParamSpec pspec, Json.Node property_node) {
		value = Value(pspec.value_type);
		return this.default_deserialize_property(property_name, value, pspec, property_node);
	}
	public unowned ParamSpec find_property(string name) {
		return this.get_class().find_property(name);
	}
}
