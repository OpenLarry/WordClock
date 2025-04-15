using WordClock;
using Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.ButtonHandler : GLib.Object, SignalSource, Jsonable {
	private TreeMap<string,bool> states = new TreeMap<string,bool>();
	private Cancellable? hold = null;
	private bool hold_executed = false;
	
	public void add_input( DevInput input ) {
		input.action.connect( (val) => {
			string[] parts = val.split("-");
			if(parts.length == 1)
				return this.button_action( parts[0], true );
			else if(parts.length == 2 && parts[1] == "release")
				return this.button_action( parts[0], false );
			else
				return false;
		});
	}
	
	public bool button_action( string name, bool pressed ) {
		if(pressed) {
			this.states[name] = true;
			
			this.button_hold.begin();
			return false;
		} else {
			string event = "";
			foreach(Map.Entry<string,bool> e in this.states.entries) {
				if(e.value) {
					e.value = false; 
					event += e.key;
				}
			}
			
			if(event == "") return false;
			if(this.hold != null) this.hold.cancel();
			if(this.hold_executed) return true;
			
			return this.action( event );
		}
	}
	
	private async void button_hold() {
		if(this.hold != null && !this.hold.is_cancelled()) return;
		this.hold = new Cancellable();
		this.hold_executed = false;
		
		for(uint secs = 1; !this.hold.is_cancelled(); secs++) {
			yield async_sleep( 1000, this.hold );
			
			if(!this.hold.is_cancelled()) {
				string event = "";
				foreach(Map.Entry<string,bool> e in this.states.entries) {
					if(e.value) {
						event += e.key;
					}
				}
				if(this.action( event+"-"+secs.to_string() )) {
					this.hold_executed = true;
				}
			}
		}
	}
}
