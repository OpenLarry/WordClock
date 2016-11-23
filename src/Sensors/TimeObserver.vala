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
		var datetime = new DateTime.now(Main.timezone);
		this.t2 = datetime.to_unix() + datetime.get_utc_offset() / 1000000;
		
		this.check_events();
	}
	
	public void check_events() {
		var datetime = new DateTime.now(Main.timezone);
		this.t1 = this.t2;
		uint sleep = (uint) (SLEEP_TIME - ((datetime.to_unix() + datetime.get_utc_offset() / 1000000) % SLEEP_TIME));
		GLib.Timeout.add_seconds( sleep, () => {
			datetime = new DateTime.now(Main.timezone);
			this.t2 = datetime.to_unix() + datetime.get_utc_offset() / 1000000;
			int64 dt = this.t2 - this.t1;
			
			if (dt < 0 || dt >= 2 * 60) {
				stdout.printf("TimeObserver: Time disparity of %"+int64.FORMAT+" seconds detected!\n", dt);
			}else{
				foreach(var entry in this.events.entries) {
					bool action = false;
					foreach(TimeEvent event in entry.value) {
						if( event.check((uint)(this.t1 % 604800), (uint)(this.t2 % 604800)) ) action = true;
					}
					if(action) this.action( entry.key );
				}
			}
			
			this.check_events();
			return GLib.Source.REMOVE;
		});
	}
	
	public class TimeEvent : GLib.Object, Jsonable {
		public uint interval { get; set; default = 60; }
		public uint start { get; set; default = 0; }
		
		public bool check( uint t1, uint t2 ) {
			if(this.interval == 0) return false;
			
			uint interval = this.interval * 60;
			uint start = (this.start % this.interval) * 60;
			
			return t1 < ((t2 - start) / interval) * interval + start;
		}
	}
}
