
using WordClock;
using Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.GoogleLocationProvider : GLib.Object, Jsonable, LocationProvider {
	const string GOOGLE_LOCATION_API = "https://www.googleapis.com/geolocation/v1/geolocate?key=AIzaSyAY8X2PHxod0tWS5BC-HGFl_t6BQLrIVEc";
	
	const uint RETRY_COUNT = 10;
	const uint RETRY_INTERVAL = 60;
	
	const uint SCAN_COUNT = 3;
	const uint SCAN_INTERVAL = 5;
	
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
		
		// generate request body
		Json.Array arr = new Json.Array();
		
		WirelessNetworks wireless = new WirelessNetworks();
		ArrayList<WirelessNetwork> networks = wireless.scan_networks(3);
		foreach(WirelessNetwork network in networks) {
			Json.Object obj = new Json.Object();
			obj.set_string_member("macAddress",network.mac);
			arr.add_object_element(obj);
		}
		
		Json.Object obj = new Json.Object();
		obj.set_array_member("wifiAccessPoints",arr);
		
		Json.Node node = new Json.Node( Json.NodeType.OBJECT );
		node.take_object(obj);
		
		// send request
		Soup.Message msg = new Soup.Message("POST", GOOGLE_LOCATION_API);
		msg.set_request("application/json", Soup.MemoryUse.COPY, JsonHelper.to_string(node).data);
		
		debug("Send request to Google Location API");
		ses.send_message(msg);
		
		if(msg.status_code != 200) throw new IOError.FAILED("Got status code: %u: %s\n", msg.status_code, msg.reason_phrase);
		
		// parse reponse body
		node = JsonHelper.from_string( (string) msg.response_body.data );
		
		if(node.get_node_type() == Json.NodeType.OBJECT &&
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
