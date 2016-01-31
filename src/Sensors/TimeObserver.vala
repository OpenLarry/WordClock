using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.TimeObserver : GLib.Object, Jsonable, SignalSource {
	public JsonableTreeMapArrayList<TimeEvent> events { get; set; default = new JsonableTreeMapArrayList<TimeEvent>(); }
	
	public TimeObserver() {
		GLib.Timeout.add_seconds( 60, () => {
			var datetime = new DateTime.now_local();
		
			uint time = (uint) ((datetime.to_unix() + datetime.get_utc_offset() / 1000000) % 604800) / 60;
		
			foreach(var entry in this.events.entries) {
				foreach(TimeEvent event in entry.value) {
					if( event.check(time) ) this.action( entry.key );
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
