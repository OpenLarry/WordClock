using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Settings : GLib.Object, Jsonable {
	private uint timeout = 0;
	
	private string path;
	private TreeMap<Type, Jsonable> type_map = new TreeMap<Type, Jsonable>();
	
	public uint save_time { get; set; default = 5; }
	public JsonableTreeMap<Jsonable> objects { get; set; default = new JsonableTreeMap<Jsonable>(); }
	
	public Settings() {
		this.path = SettingsMigrator.get_settings_path();
	}

	public new T get<T>() {
		return (T) type_map[typeof(T)];
	}

	public new void set(string key, Jsonable val) {
		type_map[val.get_class().get_type()] = val;
		objects[key] = val;
	}
	
	public void load( string? version = null ) throws Error {
		if(version == null) {
			try {
				// load settings
				debug("Load settings: %s", this.path);
				JsonHelper.load( this, this.path );
				debug("Settings loaded");
			} catch ( Error e ) {
				if(e is FileError.NOENT) {
					string? old_version = SettingsMigrator.get_old_settings_version();
					if(old_version == null) {
						// if there is no settings file from a prior version -> load default settings
						this.load("defaults");
					}else{
						// migrate old settings to new version
						string old_settings = SettingsMigrator.get_settings_path(old_version);
						debug("Load settings: %s", old_settings);
						Json.Parser parser = new Json.Parser();
						parser.load_from_file(old_settings);
						Json.Node node = parser.get_root();
						try {
							SettingsMigrator.migrate(new JsonWrapper.Node(node), old_version);
							this.from_json(node);
						} catch ( Error e ) {
							Buzzer.beep(200,2000,255);
							Buzzer.pause(200);
							Buzzer.beep(200,2000,255);
							Buzzer.pause(200);
							Buzzer.beep(200,2000,255);
							
							// wait for buzzer
							Thread.usleep(1500000);
							
							error("Migration failed: %s", e.message);
						}
						debug("Settings loaded");
						this.save();
					}
				}else{
					throw e;
				}
			}
		}else{
			string settings = SettingsMigrator.get_settings_path(version);
			debug("Load settings: %s", settings);
			JsonHelper.load( this, settings );
			debug("Settings loaded");
		}
	}
	
	public void save( string? path = null ) throws Error {
		lock(this.timeout) {
			if(this.timeout > 0) GLib.Source.remove(this.timeout);
			this.timeout = 0;
		}
		JsonHelper.save( this, path ?? this.path, true );
		debug("Settings saved");
	}
	
	public void check_save() throws Error {
		if(this.timeout > 0) this.save();
	}
	
	public void deferred_save() {
		lock(this.timeout) {
			if(this.timeout > 0) GLib.Source.remove(this.timeout);
			this.timeout = GLib.Timeout.add_seconds(this.save_time, () => {
				try{
					this.save();
				}catch( Error e ) {
					warning(e.message);
				}
				return GLib.Source.REMOVE;
			});
		}
	}
}
