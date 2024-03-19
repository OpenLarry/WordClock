
using WordClock;
using Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.GoogleLocationProvider : GLib.Object, Jsonable, LocationProvider {
	const string GOOGLE_LOCATION_API = "https://www.googleapis.com/geolocation/v1/geolocate";
	
	const uint8 RETRY_COUNT = 10;
	const uint8 RETRY_INTERVAL = 60;
	
	const uint8 SCAN_COUNT = 3;
	const uint8 SCAN_INTERVAL = 5;
	
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

	public string apikey {
		get {
			return this._apikey;
		}
		set {
			if(value != this._apikey) {
				this._apikey = value;
				this.async_refresh.begin();
			}
		}
	}
	private string _apikey = "";
	
	private uint timeout = 0;
	private bool refresh_running = false;
	
	private LocationInfo? location = null;
	
	construct {
		this.async_refresh.begin();
		this.set_timeout();
	}
	
	protected void set_timeout() {
		if(this.timeout > 0) GLib.Source.remove(this.timeout);
		if(this.refresh_interval > 0) {
			this.timeout = GLib.Timeout.add_seconds(this.refresh_interval, () => {
				// ignore timeout if no other reference is held anymore
				if(this.ref_count == 1) return GLib.Source.REMOVE;
				
				this.async_refresh.begin();
				return GLib.Source.CONTINUE;
			});
		}else{
			this.timeout = 0;
		}
	}
	
	public LocationInfo? get_location() {
		return this.location;
	}
	
	public async void async_refresh() {
		if(this.apikey.length == 0) return;

		if(this.refresh_running) return;
		this.refresh_running = true;
		
		for(uint8 i=0;i<RETRY_COUNT;i++) {
			try{
				yield this.refresh();
				break;
			} catch ( Error e ) {
				warning(e.message);
				yield async_sleep(RETRY_INTERVAL*1000);
			}
		}
		
		this.refresh_running = false;
	}
	
	private async void refresh() throws Error {
		debug("Starting refresh");
		
		Soup.Session ses = new Soup.Session();
		ses.proxy_resolver = null;
		ses.ssl_strict = false;
		ses.tls_database = null;
		
		ArrayList<WirelessNetwork> networks = yield Main.settings.get<WirelessNetworks>().scan_networks(SCAN_COUNT, SCAN_INTERVAL);
		
		JsonWrapper.Node node = new JsonWrapper.Node.empty( Json.NodeType.OBJECT );
		node["wifiAccessPoints"] = new JsonWrapper.Node.empty( Json.NodeType.ARRAY );
		foreach(WirelessNetwork network in networks) {
			JsonWrapper.Node obj = new JsonWrapper.Node.empty( Json.NodeType.OBJECT );
			obj["macAddress"] = network.mac;
			node["wifiAccessPoints"][-1] = obj;
		}

		Soup.URI uri = new Soup.URI(GOOGLE_LOCATION_API);
		HashTable<string,string> query = new HashTable<string,string>(str_hash, null);
		query.insert("key", this.apikey);
		uri.set_query_from_form(query);
		
		// send request
		Soup.Message msg = new Soup.Message.from_uri("POST", uri);
		msg.set_request("application/json", Soup.MemoryUse.COPY, node.to_json_string().data);
		
		debug("Send request to Google Location API");
		InputStream input = yield ses.send_async(msg);
		
		if(msg.status_code != 200) throw new IOError.FAILED("Got status code: %u: %s\n", msg.status_code, msg.reason_phrase);
		
		uint8[] data = new uint8[1024];
		size_t data_length;
		yield input.read_all_async(data, Priority.DEFAULT_IDLE, null, out data_length);
		
		// parse response body
		node = new JsonWrapper.Node.from_json_string( (string) data[0:data_length] );
		
		this.location = new LocationInfo(
			(double) node["location"]["lat"].get_typed_value(typeof(double)),
			(double) node["location"]["lng"].get_typed_value(typeof(double)),
			(int) node["accuracy"].get_typed_value(typeof(int))
		);
		
		debug("Finished refresh");
		
		this.update();
	}
}
