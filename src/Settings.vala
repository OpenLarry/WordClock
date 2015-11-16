using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Settings : GLib.Object, Jsonable {
	private uint timeout = 0;
	private int source = 0;
	
	public string path;
	
	public uint save_time { get; set; default = 5000; }
	public JsonableTreeMap<Jsonable> objects { get; set; default = new JsonableTreeMap<Jsonable>(); }
	
	public Settings( string path ) {
		this.path = path;
	}
	
	public void load( ) throws Error {
		JsonHelper.load( this, path );
	}
	
	public void save() throws Error {
		lock(source) {
			if(this.timeout > 0) GLib.Source.remove(this.timeout);
			this.timeout = 0;
		}
		JsonHelper.save( this, path, true );
	}
	
	public void deferred_save() throws Error {
		lock(source) {
			if(this.timeout > 0) GLib.Source.remove(this.timeout);
			this.timeout = GLib.Timeout.add(this.save_time, () => {
				try{
					this.save();
				}catch( Error e ) {
					stderr.printf("Error: %s\n", e.message);
				}
				return false;
			});
		}
	}
}
