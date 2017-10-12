using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.SettingsMigrator : GLib.Object {
	const string SETTINGS_PATH = "/etc/wordclock/";
	
	[CCode (has_target=false)]
	private delegate void MigrationFunc( ref Json.Node node ) throws Error;
	
	public static void migrate( ref Json.Node node, string from = get_old_settings_version(), string to = Version.GIT_DESCRIBE) throws Error {
		if(!Version.is_official(from)) throw new SettingsMigratorError.INVALID_VERSION("Invalid version: %s".printf(from ?? "null"));
		if(Version.is_official(to) && Version.compare(from,to) >= 0) throw new SettingsMigratorError.INVALID_VERSION("Invalid version: %s".printf(to));
		
		debug("Migrate settings from version %s to %s", (from=="") ? "none" : from, to);
		
		TreeMap<string,MigrationFunc> migration_funcs = get_migration_funcs();
		foreach(Map.Entry<string,MigrationFunc> e in migration_funcs.entries) {
			if(Version.compare(from,e.key) <= 0 && (!Version.is_official(to) || Version.compare(e.key,to) < 0)) {
				debug("Migration from version %s", (e.key=="") ? "none" : e.key);
				e.value(ref node);
			}
		}
		
		debug("Migration done");
	}
	
	private static TreeMap<string,MigrationFunc> get_migration_funcs() {
		TreeMap<string,MigrationFunc> migration_funcs = new TreeMap<string,MigrationFunc>(Version.compare);
		
		migration_funcs[""] = (ref node) => {
			debug("Update $.objects.signalrouter.sinks: Replace motion with filteredmotion");
			Json.Node sinks = get_first_node("$.objects.signalrouter.sinks", ref node);
			
			if(sinks.get_node_type() != Json.NodeType.OBJECT) throw new SettingsMigratorError.MIGRATION_FAILED("get_node_type != Json.NodeType.OBJECT");
			
			if(sinks.get_object().has_member("motion,1")) {
				Json.Node member = sinks.get_object().get_member("motion,1");
				sinks.get_object().remove_member("motion,1");
				sinks.get_object().set_member("filteredmotion,1", member);
			}
			
			debug("Update $.objects.signalrouter.sinks: Bind WirelessNetworkInputSink with delay to same key as InfoSink");
			foreach(string name in sinks.get_object().get_members()) {
				MatchInfo info;
				if(/^remote,\w+(?!-\d+)$/.match(name, 0, out info)) {
					if(sinks.get_object().has_member( info.fetch(0)+"-10" )) continue;
					if(sinks.get_object().get_member(name).get_node_type() != Json.NodeType.ARRAY) continue;
					Json.Array member = sinks.get_object().get_array_member(name);
					
					// check if current signal has WordClockInfoSink
					bool found = false;
					foreach(unowned Json.Node val in member.get_elements()) {
						if(val.get_node_type() != Json.NodeType.OBJECT) continue;
						if(!val.get_object().has_member("-type")) continue;
						if(val.get_object().get_member("-type").get_node_type() != Json.NodeType.VALUE) continue;
						if(val.get_object().get_string_member("-type") != "WordClockInfoSink") continue;
						
						found = true;
						break;
					}
					
					// add WordClockWirelessNetworkInputSink
					if(found) {
						Json.Object obj = new Json.Object();
						obj.set_string_member("-type","WordClockWirelessNetworkInputSink");
						
						Json.Array arr = new Json.Array();
						arr.add_object_element(obj);
						
						sinks.get_object().set_array_member(info.fetch(0)+"-10", arr);
					}
				}
			}
			
			debug("Update $.objects.signalrouter.userevent-sources: Replace motion with filteredmotion");
			sinks = get_first_node("$.objects.signalrouter.userevent-sources", ref node);
			
			if(sinks.get_node_type() != Json.NodeType.ARRAY) throw new SettingsMigratorError.MIGRATION_FAILED("get_node_type != Json.NodeType.ARRAY");
				
			for(int i=0;i<sinks.get_array().get_length();i++) {
				Json.Node elem = sinks.get_array().get_element(i);
				if(elem.get_node_type() == Json.NodeType.VALUE && elem.get_string() == "motion") {
					sinks.get_array().remove_element(i--);
					sinks.get_array().add_string_element("filteredmotion");
				}
			}
		};
		
		migration_funcs["v0.8"] = (ref node) => {
			debug("Update $.objects.clockrenderer.renderers: Replace StringRenderer with TextRenderer");
			Json.Node renderers = get_first_node("$.objects.clockrenderer.renderers", ref node);
			
			if(renderers.get_node_type() != Json.NodeType.OBJECT) throw new SettingsMigratorError.MIGRATION_FAILED("get_node_type != Json.NodeType.OBJECT");
			
			foreach(unowned Json.Node renderer in renderers.get_object().get_values()) {
				if(renderer.get_node_type() != Json.NodeType.OBJECT) throw new SettingsMigratorError.MIGRATION_FAILED("get_node_type != Json.NodeType.OBJECT");
				
				if(!renderer.get_object().has_member("-type")) continue;
				if(renderer.get_object().get_member("-type").get_node_type() != Json.NodeType.VALUE) continue;
				if(renderer.get_object().get_string_member("-type") != "WordClockStringRenderer") continue;
				
				if(renderer.get_object().has_member("left-color")) {
					Json.Node member = renderer.get_object().get_member("left-color");
					renderer.get_object().remove_member("left-color");
					renderer.get_object().set_member("color", member);
				}
				if(renderer.get_object().has_member("right-color")) {
					renderer.get_object().remove_member("right-color");
				}
				if(renderer.get_object().has_member("speed")) {
					Json.Node member = renderer.get_object().get_member("speed");
					renderer.get_object().remove_member("speed");
					renderer.get_object().set_member("x-speed", member);
				}
				if(renderer.get_object().has_member("position")) {
					Json.Node member = renderer.get_object().get_member("position");
					renderer.get_object().remove_member("position");
					renderer.get_object().set_member("x-offset", member);
				}
				if(renderer.get_object().has_member("add-spacing")) {
					Json.Node member = renderer.get_object().get_member("add-spacing");
					renderer.get_object().remove_member("add-spacing");
					renderer.get_object().set_member("letter-spacing", member);
				}
				if(renderer.get_object().has_member("font-name")) {
					Json.Node member = renderer.get_object().get_member("font-name");
					if(member.get_node_type() == Json.NodeType.VALUE && member.get_string() == "WordClockHugeMicrosoftSansSerifFont") {
						renderer.get_object().set_string_member("font", "DejaVuSans 10.5");
						renderer.get_object().set_int_member("y-offset", 9);
						renderer.get_object().set_int_member("hint-style", 3);
					}
					renderer.get_object().remove_member("font-name");
				}
				if(renderer.get_object().has_member("string")) {
					Json.Node member = renderer.get_object().get_member("string");
					renderer.get_object().remove_member("string");
					renderer.get_object().set_member("text", member);
				}
				
				renderer.get_object().set_string_member("-type","WordClockTextRenderer");
			}
		};
		
		return migration_funcs;
	}
	
	private static Json.Node? get_first_node(string path, ref Json.Node node) throws Error {
		Json.Node path_node = Json.Path.query(path, node);
		if(path_node.get_node_type() != Json.NodeType.ARRAY) throw new SettingsMigratorError.MIGRATION_FAILED("get_node_type != Json.NodeType.ARRAY");
		if(path_node.get_array().get_length() == 0) throw new SettingsMigratorError.MIGRATION_FAILED("get_length == 0");
		
		return path_node.get_array().get_element(0);
	}
	
	public static string get_current_settings_version() {
		return Version.is_official() ? Version.GIT_DESCRIBE : "dev";
	}
	
	public static string? get_old_settings_version() {
		try{
			Dir dir = Dir.open(SETTINGS_PATH, 0);
			
			ArrayList<string> list = new ArrayList<string>();
			string? name;
			while((name = dir.read_name()) != null) {
				MatchInfo info;
				if(/^settings\.(v(\d+\.??)+)?\.?json$/.match(name, 0, out info)) {
					string version = info.fetch(1) ?? "";
					if(!Version.is_official() || Version.compare(Version.GIT_DESCRIBE, version) > 0) list.add(version);
				}
			}
			list.sort(Version.compare);
			
			return (list.size > 0) ? list.last() : null;
		} catch ( Error e ) {
			error("Cannot get old settings version: %s", e.message);
		}
	}
	
	public static string get_settings_path( string version = get_current_settings_version()) {
		if(version == "defaults") {
			return @"$(SETTINGS_PATH)defaults.json";
		}else if(version != "") {
			return @"$(SETTINGS_PATH)settings.$version.json";
		}else{
			return @"$(SETTINGS_PATH)settings.json";
		}
	}
}

public errordomain WordClock.SettingsMigratorError {
	MIGRATION_FAILED,
	INVALID_VERSION
}