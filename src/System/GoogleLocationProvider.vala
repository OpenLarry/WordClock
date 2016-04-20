using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.GoogleLocationProvider : GLib.Object, Jsonable, LocationProvider {
	const string GOOGLE_LOCATION_API = "https://maps.googleapis.com/maps/api/browserlocation/json";
	
	const uint RETRY_COUNT = 10;
	const uint RETRY_INTERVAL = 60;
	
	public uint refresh_interval {
		get {
			return this._refresh_interval;
		}
		set {
			if(value != this._refresh_interval) {
				this._refresh_interval = value;
				this.set_timeout();
			}
		}
	}
	private uint _refresh_interval = 86400;
	
	private uint timeout = 0;
	private bool refresh_running = false;
	
	private LocationInfo? location = null;
	
	construct {
		this.threaded_refresh();
		this.set_timeout();
	}
	
	protected void set_timeout() {
		if(this.timeout > 0) GLib.Source.remove(this.timeout);
		if(this.refresh_interval > 0) {
			this.timeout = GLib.Timeout.add_seconds(this.refresh_interval, () => {
				this.threaded_refresh();
				return GLib.Source.CONTINUE;
			});
		}else{
			this.timeout = 0;
		}
	}
	
	public LocationInfo? get_location() {
		return this.location;
	}
	
	public void threaded_refresh() {
		if(this.refresh_running) return;
		
		this.refresh_running = true;
		new Thread<int>("googlelocation", () => {
			// set idle scheduling policy
			Posix.Sched.Param param = { 0 };
			int ret = Posix.Sched.setscheduler(0, Posix.Sched.Algorithm.IDLE, ref param);
			GLib.assert(ret==0); GLib.debug("Set scheduler");
			
			// retry on error
			for(uint i=0;i<RETRY_COUNT;i++) {
				try{
					this.refresh();
					break;
				} catch ( Error e ) {
					stderr.printf("Error %s\n", e.message);
					Thread.usleep(RETRY_INTERVAL*1000000);
				}
			}
			
			this.refresh_running = false;
			return 0;
		});
	}
	
	public void refresh() throws Error {
		Soup.Session ses = new Soup.SessionSync();
		Soup.URI uri = new Soup.URI(GOOGLE_LOCATION_API);
		HashTable<string,string> query = new HashTable<string,string>(str_hash, null);
		
		query.insert("browser","firefox");
		query.insert("sensor","true");
		
		string output;
		try{
			Process.spawn_sync("/bin", {"nice","-10","iwlist","wlan0","scan"}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, out output);
			
			Regex regex = /Address: ((?:[\dA-F]{2}:){5}[\dA-F]{2})\n.*ESSID:"(\S+)"/;
			MatchInfo match_weather;
			if( regex.match( output, 0, out match_weather ) ) {
				do {
					query.insert("wifi","mac:"+match_weather.fetch(1).replace(":","-")+"|ssid:"+match_weather.fetch(2));
				} while ( match_weather.next() );
			}
		}catch(Error e) {
			stderr.printf("%s\n",e.message);
		}
		
		uri.set_query_from_form( query );
		Soup.Message msg = new Soup.Message.from_uri("GET", uri);
		ses.send_message(msg);
		
		if(msg.status_code != 200) throw new IOError.FAILED("Got status code: %u: %s\n", msg.status_code, msg.reason_phrase);
		
		Json.Node node = JsonHelper.from_string( (string) msg.response_body.data );
		
		Json.Object obj;
		if(node.get_node_type() == Json.NodeType.OBJECT &&
		   node.get_object().has_member("status") &&
		   node.get_object().get_string_member("status") == "OK" &&
		   node.get_object().has_member("accuracy") &&
		   node.get_object().has_member("location")) {
			obj = node.get_object().get_object_member("location");
			if(obj != null &&
			   obj.has_member("lat") &&
			   obj.has_member("lng")) {
				LocationInfo location = new LocationInfo(obj.get_double_member("lat"),obj.get_double_member("lng"),(int) node.get_object().get_int_member("accuracy"));
				
				this.location = location;
				this.update();
			}
		}
	}
}
