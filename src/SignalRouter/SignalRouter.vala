using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.SignalRouter : GLib.Object, Jsonable {
	protected TreeMap<string,SignalSource> sources = new TreeMap<string,SignalSource>();
	
	public JsonableTreeMapArrayList<SignalSink> sinks { get; set; default = new JsonableTreeMapArrayList<SignalSink>(); }
	public JsonableArrayList<JsonableString> userevent_sources { get; set; default = new JsonableArrayList<JsonableString>(
		(a,b) => { return a.to_string() == b.to_string(); }
	); }
	
	public void add_source( string source_name, SignalSource source ) {
		sources[source_name] = source;
		source.action.connect( (name) => {
			this.action( source_name, name );
		});
	}
	
	
	protected void action ( string source_name, string action_name ) {
		if(source_name != "signalrouter" && userevent_sources.contains(new JsonableString(source_name))) {
			this.action("signalrouter","userevent");
		}
		
		var sinks = this.sinks[source_name+","+action_name];
		if(sinks == null) return;
		
		
		foreach(var sink in sinks) {
			sink.action();
		}
	}
}
