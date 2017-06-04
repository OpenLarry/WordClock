using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Settings : GLib.Object, Jsonable {
	private uint timeout = 0;
	
	public string path;
	
	public uint save_time { get; set; default = 5; }
	public JsonableTreeMap<Jsonable> objects { get; set; default = new JsonableTreeMap<Jsonable>(); }
	
	public Settings( string path ) {
		this.path = path;
	}
	
	public void load( string? path = null ) throws Error {
		JsonHelper.load( this, path ?? this.path );
		debug("Settings loaded");
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
