
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
				// ignore timeout if no other reference is held anymore
				if(this.ref_count == 1) return GLib.Source.REMOVE;
				
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
			assert(ret==0);
			
			// retry on error
			for(uint i=0;i<RETRY_COUNT;i++) {
				try{
					this.refresh();
					break;
				} catch ( Error e ) {
					warning(e.message);
					Thread.usleep(RETRY_INTERVAL*1000000);
				}
			}
			
			this.refresh_running = false;
			return 0;
		});
	}
	
	public void refresh() throws Error {
		debug("Starting refresh");
		
		Soup.Session ses = new Soup.Session();
		ses.proxy_resolver = null;
		ses.ssl_strict = false;
		ses.tls_database = null;
		Soup.URI uri = new Soup.URI(GOOGLE_LOCATION_API);
		HashTable<string,string> query = new HashTable<string,string>(str_hash, null);
		
		query.insert("browser","firefox");
		query.insert("sensor","true");
		
		
		WirelessNetworks wireless = new WirelessNetworks();
		JsonableArrayList<WirelessNetwork> networks = wireless.scan_networks();
		foreach(WirelessNetwork network in networks) {
			query.insert("wifi","mac:"+network.mac+"|ssid:"+network.ssid);
		}
		
		uri.set_query_from_form( query );
		
		debug("Request URL %s", uri.to_string(false));
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
		
		debug("Finished refresh");
	}
}
