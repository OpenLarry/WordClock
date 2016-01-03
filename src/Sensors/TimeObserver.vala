using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.TimeObserver : GLib.Object, Jsonable, SignalSource {
	public JsonableTreeMultiMap<TimeEvent> events { get; set; default = new JsonableTreeMultiMap<TimeEvent>(); }
	
	public TimeObserver() {
		GLib.Timeout.add_seconds( 60, () => {
			var datetime = new DateTime.now_local();
		
			uint time = (uint) ((datetime.to_unix() + datetime.get_utc_offset() / 1000000) % 604800) / 60;
		
			foreach(string key in this.events.get_keys()) {
				foreach(TimeEvent event in this.events[key]) {
					if( event.check(time) ) this.action( key );
				}
			}
			
			return true;
		});
	}
	
	public class TimeEvent : GLib.Object, Jsonable {
		public uint interval { get; set; default = 60; }
		public uint start { get; set; default = 0; }
		
		public bool check( uint time ) {
			return time % this.interval == this.start;
		}
	}
}
