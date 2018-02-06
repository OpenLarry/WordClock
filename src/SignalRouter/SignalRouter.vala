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
	
	
	public class SignalFuncWrapper {
		public Regex regex;
		public unowned SignalFunc f;
		public bool before;
		
		public SignalFuncWrapper(Regex regex, SignalFunc f, bool before) {
			this.regex = regex;
			this.f = f;
			this.before = before;
		}
	}
	
	public delegate bool SignalFunc( uint id, string signal_name, out bool proceed = null );
	protected TreeMap<uint,SignalFuncWrapper> signal_funcs = new TreeMap<uint,SignalFuncWrapper>();
	protected uint signal_funcs_count = 0;
	
	
	
	public void add_source( string source_name, SignalSource source ) {
		sources[source_name] = source;
		source.action.connect( (name) => {
			return this.trigger_signal( source_name+","+name );
		});
	}
	
	public bool trigger_signal( string signal_name ) {
		bool handled = false;
		
		if(signal_name != "signalrouter,userevent") {
			string[] parts = signal_name.split(",",2);
			if(parts.length > 0 && userevent_sources.contains(new JsonableString(parts[0]))) {
				this.trigger_signal("signalrouter,userevent");
			}
		}
		
		debug("Trigger signal %s", signal_name);
		
		foreach(Map.Entry<uint,SignalFuncWrapper> entry in this.signal_funcs.entries) {
			if(entry.value.before && entry.value.regex.match(signal_name)) {
				bool proceed;
				if(entry.value.f(entry.key, signal_name, out proceed)) handled = true;
				if(!proceed) return handled;
			}
		}
		
		var sinks = this.sinks[signal_name];
		if(sinks != null) {
			foreach(var sink in sinks) {
				handled = true;
				sink.action();
			}
		}
		
		foreach(Map.Entry<uint,SignalFuncWrapper> entry in this.signal_funcs.entries) {
			if(!entry.value.before && entry.value.regex.match(signal_name)) {
				bool proceed;
				if(entry.value.f(entry.key, signal_name, out proceed)) handled = true;
				if(!proceed) return handled;
			}
		}
		
		return handled;
	}
	
	public uint add_signal_func( Regex regex, SignalFunc func, bool before = false ) {
		this.signal_funcs[this.signal_funcs_count] = new SignalFuncWrapper(regex,func,before);
		
		return this.signal_funcs_count++;
	}
	
	public bool remove_signal_func( uint id ) {
		return this.signal_funcs.unset(id);
	}
}
