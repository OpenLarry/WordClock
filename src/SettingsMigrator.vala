using WordClock, Gee, JsonWrapper;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.SettingsMigrator : GLib.Object {
	const string SETTINGS_PATH = "/etc/wordclock/";
	
	[CCode (has_target=false)]
	private delegate void MigrationFunc( JsonWrapper.Node node ) throws JsonWrapper.Error;
	private delegate void RecursiveMigrationFunc( JsonWrapper.Node node ) throws JsonWrapper.Error;
	
	public static void migrate( JsonWrapper.Node node, string from = get_old_settings_version(), string to = Version.GIT_DESCRIBE) throws GLib.Error {
		if(!Version.is_official(from)) throw new SettingsMigratorError.INVALID_VERSION("Invalid version: %s".printf(from ?? "null"));
		if(Version.is_official(to) && Version.compare(from,to) >= 0) throw new SettingsMigratorError.INVALID_VERSION("Invalid version: %s".printf(to));
		
		debug("Migrate settings from version %s to %s", (from=="") ? "none" : from, to);
		
		TreeMap<string,MigrationFunc> migration_funcs = get_migration_funcs();
		foreach(Map.Entry<string,MigrationFunc> e in migration_funcs.entries) {
			if(Version.compare(from,e.key) <= 0 && (!Version.is_official(to) || Version.compare(e.key,to) < 0)) {
				debug("Migration from version %s", (e.key=="") ? "none" : e.key);
				e.value(node);
			}
		}
		
		debug("Migration done");
	}
	
	private static TreeMap<string,MigrationFunc> get_migration_funcs() {
		TreeMap<string,MigrationFunc> migration_funcs = new TreeMap<string,MigrationFunc>(Version.compare);
		
		migration_funcs[""] = (node) => {
			debug("Update $.objects.signalrouter.sinks: Replace motion with filteredmotion");
			JsonWrapper.Node sinks = node["objects"]["signalrouter"]["sinks"];
			
			try {
				sinks["filteredmotion,1"] = sinks["motion,1"];
				sinks["motion,1"].remove();
			} catch ( JsonWrapper.Error e ) {
				if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
			}
			
			debug("Update $.objects.signalrouter.sinks: Bind WirelessNetworkInputSink with delay to same key as InfoSink");
			foreach(Entry entry in sinks) {
				MatchInfo info;
				// check if there is already a delayed sink
				if(! (/^remote,\w+(?!-\d+)$/.match(entry.get_member_name(), 0, out info))) continue;
				string new_key = info.fetch(0)+"-10";
				if(sinks.has(new_key)) continue;
				
				// check if current signal has WordClockInfoSink
				foreach(Entry elem in entry.value) {
					try {
						if(elem.value["-type"].to_string() == "WordClockInfoSink") {
							// add WordClockWirelessNetworkInputSink
							sinks[new_key] = new JsonWrapper.Node.empty( Json.NodeType.ARRAY );
							sinks[new_key][0] = new JsonWrapper.Node.empty( Json.NodeType.OBJECT );
							sinks[new_key][0]["-type"] = "WordClockWirelessNetworkInputSink";
							break;
						}
					} catch ( JsonWrapper.Error e ) {
						// ignore
					}
				}
			}
			
			debug("Update $.objects.signalrouter.userevent-sources: Replace motion with filteredmotion");
			JsonWrapper.Node sources = node["objects"]["signalrouter"]["userevent-sources"];
			
			foreach(Entry source in sources) {
				if(source.value.to_string() == "motion") source.value.set_value("filteredmotion");
			}
		};
		
		migration_funcs["v0.8.2"] = (node) => {
			debug("Update $.objects.clockrenderer.renderers: Replace StringRenderer with TextRenderer");
			JsonWrapper.Node renderers = node["objects"]["clockrenderer"]["renderers"];
			
			foreach(Entry renderer in renderers) {
				try {
					if(renderer.value["-type"].to_string() != "WordClockStringRenderer") continue;
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}
				
				try {
					renderer.value["color"] = renderer.value["left-color"];
					renderer.value["left-color"].remove();
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}					
					
				try {
					renderer.value["right-color"].remove();
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}
				
				try {
					renderer.value["x-speed"] = renderer.value["speed"];
					renderer.value["speed"].remove();
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}

				try {
					renderer.value["x-offset"] = renderer.value["position"];
					renderer.value["position"].remove();
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}

				try {
					renderer.value["letter-spacing"] = renderer.value["add-spacing"];
					renderer.value["add-spacing"].remove();
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}

				try {
					if(renderer.value["font-name"].to_string() == "WordClockHugeMicrosoftSansSerifFont") {
						renderer.value["font"] = "DejaVuSans 14px";
						renderer.value["y-offset"] = 12;
					}
					renderer.value["font-name"].remove();
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}

				try {
					renderer.value["text"] = renderer.value["string"];
					renderer.value["string"].remove();
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}
				
				renderer.value["-type"] = "WordClockTextRenderer";
			}
			
			debug("Update $.objects.clockrenderer.renderers: Replace BigDigitRenderer with TextRenderer");
			foreach(Entry renderer in renderers) {
				try {
					if(renderer.value["-type"].to_string() != "WordClockBigDigitRenderer") continue;
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}
				
				try {
					renderer.value["background-color"].remove();
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}
				
				try {
					renderer.value["color"] = renderer.value["foreground-color"];
					renderer.value["foreground-color"].remove();
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}

				try {
					renderer.value["text"] = renderer.value["format"];
					renderer.value["format"].remove();
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}
				
				try {
					renderer.value["font-name"].remove();
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}
				
				renderer.value["x-speed"] = 0;
				renderer.value["x-offset"] = 11;
				renderer.value["letter-spacing"] = 0;
				renderer.value["-type"] = "WordClockTextRenderer";
			}
			
			debug("Update $.objects.clockrenderer.renderers: Update words_color to words_colors");
			foreach(Entry renderer in renderers) {
				try {
					if(renderer.value["-type"].to_string() != "WordClockTimeRenderer") continue;
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}
				
				try {
					renderer.value["words-colors"] = new JsonWrapper.Node.empty( Json.NodeType.ARRAY );
					renderer.value["words-colors"][0] = renderer.value["words-color"];
					renderer.value["words-color"].remove();
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
				}
			}
			
			debug("Update $.objects.message: Migrate to TextRenderer");
			JsonWrapper.Node message = node["objects"]["message"];
			
			try {
				message["x-speed"] = message["speed"];
				message["speed"].remove();
			} catch ( JsonWrapper.Error e ) {
				if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
			}
			
			try {
				message["letter-spacing"] = message["add-spacing"];
				message["add-spacing"].remove();
			} catch ( JsonWrapper.Error e ) {
				if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
			}
			
			try {
				message["font-name"].remove();
			} catch ( JsonWrapper.Error e ) {
				if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
			}
			
			debug("Update $.objects.signalrouter.sinks: Replace signals 'remote,' with 'remote,rgb_remote-'");
			JsonWrapper.Node sinks = node["objects"]["signalrouter"]["sinks"];
			
			foreach(Entry sink in sinks) {
				MatchInfo info;
				if(/^remote,((?:UP|DOWN|OFF|ON|R|R1|R2|R3|R4|G|G1|G2|G3|G4|B|B1|B2|B3|B4|W|FLASH|STROBE|FADE|SMOOTH)(?:-\d+)?)$/.match(sink.get_member_name(), 0, out info)) {
					sinks["remote,rgb_remote-"+info.fetch(1)] = sink.value;
					sink.value.remove();
				}else if(/^remote,((?:PLAYPAUSE|POWER|W1|W2|W3|W4|RUP|RDOWN|DIY1|DIY4|DIY2|DIY5|DIY3|DIY6|GUP|GDOWN|BUP|BDOWN|QUICK|SLOW|AUTO|FADE7|FADE3|JUMP7|JUMP3)(?:-\d+)?)$/.match(sink.get_member_name(), 0, out info)) {
					sinks["remote,rgb_remote_big-"+info.fetch(1)] = sink.value;
					sink.value.remove();
				}
			}
			
			debug("Update $.objects.signalrouter.sinks: Replace JsonModifierSink paths 'remote,' with 'remote,rgb_remote-'");
			
			RecursiveMigrationFunc updateJsonModifierSink = null;
			updateJsonModifierSink = (sinks) => {
				// modify path if JsonModifierSink is found
				try {
					if(sinks["-type"].to_string() == "WordClockJsonModifierSink") {
						foreach(Entry path in sinks["paths"]) {
							MatchInfo info;
							if(/^\/objects\/signalrouter\/sinks\/remote,((?:UP|DOWN|OFF|ON|R|R1|R2|R3|R4|G|G1|G2|G3|G4|B|B1|B2|B3|B4|W|FLASH|STROBE|FADE|SMOOTH)(?:-\d+)?(?:\/.+)?)$/.match(path.value.to_string(), 0, out info)) {
								path.value.set_value("/objects/signalrouter/sinks/remote,rgb_remote-"+info.fetch(1));
							}else if(/^\/objects\/signalrouter\/sinks\/remote,((?:PLAYPAUSE|POWER|W1|W2|W3|W4|RUP|RDOWN|DIY1|DIY4|DIY2|DIY5|DIY3|DIY6|GUP|GDOWN|BUP|BDOWN|QUICK|SLOW|AUTO|FADE7|FADE3|JUMP7|JUMP3)(?:-\d+)?(?:\/.+)?)$/.match(path.value.to_string(), 0, out info)) {
								path.value.set_value("/objects/signalrouter/sinks/remote,rgb_remote_big-"+info.fetch(1));
							}
						}
					}
				} catch ( JsonWrapper.Error e ) { /* ignore errors */ }
				
				// go through sink nodes recursively
				try {
					foreach(Entry sink in sinks) {
						updateJsonModifierSink(sink.value);
					}
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.INVALID_NODE_TYPE) ) throw e; // skip node if not iterable
				}
			};
			
			updateJsonModifierSink(sinks);
			
			debug("Update $.objects.signalrouter.sinks: Replace button0-2,1 with buttonhandler,0-2");
			try {
				sinks["buttonhandler,0"] = sinks["button0,1"];
				sinks["button0,1"].remove();
			} catch ( JsonWrapper.Error e ) {
				if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
			}
			try {
				sinks["buttonhandler,1"] = sinks["button1,1"];
				sinks["button1,1"].remove();
			} catch ( JsonWrapper.Error e ) {
				if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
			}
			try {
				sinks["buttonhandler,2"] = sinks["button2,1"];
				sinks["button2,1"].remove();
			} catch ( JsonWrapper.Error e ) {
				if( ! (e is JsonWrapper.Error.NOT_FOUND) ) throw e; // ignore
			}
			
			debug("Update $.objects.signalrouter.sinks: Replace JsonModifierSink paths 'button0-2,1' with 'buttonhandler,0-2'");
			
			updateJsonModifierSink = (sinks) => {
				// modify path if JsonModifierSink is found
				try {
					if(sinks["-type"].to_string() == "WordClockJsonModifierSink") {
						foreach(Entry path in sinks["paths"]) {
							MatchInfo info;
							if(/^\/objects\/signalrouter\/sinks\/button([0-2]),1(\/.+)?$/.match(path.value.to_string(), 0, out info)) {
								path.value.set_value("/objects/signalrouter/sinks/buttonhandler,"+info.fetch(1)+info.fetch(2));
							}
						}
					}
				} catch ( JsonWrapper.Error e ) { /* ignore errors */ }
				
				// go through sink nodes recursively
				try {
					foreach(Entry sink in sinks) {
						updateJsonModifierSink(sink.value);
					}
				} catch ( JsonWrapper.Error e ) {
					if( ! (e is JsonWrapper.Error.INVALID_NODE_TYPE) ) throw e; // skip node if not iterable
				}
			};
			
			updateJsonModifierSink(sinks);
		};
		
		return migration_funcs;
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
		} catch ( GLib.Error e ) {
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