using WordClock, Gee;

/**
 * inspired by https://git.busybox.net/busybox/tree/miscutils/crond.c
 * 
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.TimeObserver : GLib.Object, Jsonable, SignalSource {
	public JsonableTreeMapArrayList<TimeEvent> events { get; set; default = new JsonableTreeMapArrayList<TimeEvent>(); }
	
	private int64 t1;
	private int64 t2;
	const uint SLEEP_TIME = 60;
	
	construct {
		this.t2 = get_time();
		
		this.check_events();
	}
	
	public void check_events() {
		this.t1 = this.t2;
		uint sleep = (uint) (SLEEP_TIME - (get_time() % SLEEP_TIME));
		GLib.Timeout.add_seconds( sleep, () => {
			// ignore timeout if no other reference is held anymore
			if(this.ref_count == 1) return GLib.Source.REMOVE;
			
			this.t2 = get_time();
			int64 dt = this.t2 - this.t1;
			
			if (dt < 0 || dt >= 2 * 60) {
				warning("Time disparity of %"+int64.FORMAT+" seconds detected!\n", dt);
			}else{
				foreach(var entry in this.events.entries) {
					foreach(TimeEvent event in entry.value) {
						if( event.check(this.t1, this.t2) ) {
							this.action( entry.key );
							break;
						}
					}
				}
			}
			
			this.check_events();
			return GLib.Source.REMOVE;
		});
	}
	
	
	/**
	 * Get seconds since monday 12-29-1969 00:00:00 in local timezone
	 */
	private static int64 get_time() {
		var datetime = new DateTime.now(Main.timezone);
		return datetime.to_unix() + datetime.get_utc_offset() / 1000000 + 3*24*60*60;
	}
	
	public class TimeEvent : GLib.Object, Jsonable {
		public uint interval { get; set; default = 60; }
		public uint start { get; set; default = 0; }
		
		public bool check( int64 t1, int64 t2 ) {
			uint start = (this.start % this.interval) * 60;
			
			if(this.interval == 0) return t1 < start && start <= t2;
			
			uint interval = this.interval * 60;
			
			return t1 < ((t2 - start) / interval) * interval + start;
		}
	}
}
