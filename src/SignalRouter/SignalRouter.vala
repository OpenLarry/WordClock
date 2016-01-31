using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.SignalRouter : GLib.Object, Jsonable {
	protected TreeMap<string,SignalSource> sources = new TreeMap<string,SignalSource>();
	
	public JsonableTreeMapArrayList<SignalSink> sinks { get; set; default = new JsonableTreeMapArrayList<SignalSink>(); }
	
	public void add_source( string source_name, SignalSource source ) {
		sources[source_name] = source;
		source.action.connect( (name) => {
			this.action( source_name, name );
		});
	}
	
	
	protected void action ( string source_name, string action_name ) {
		var sinks = this.sinks[source_name+","+action_name];
		if(sinks == null) return;
		
		foreach(var sink in sinks) {
			sink.action();
		}
	}
}
