using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.OWMWeatherProvider : GLib.Object, Jsonable {
	const string OWM_API = "http://api.openweathermap.org/data/2.5/weather";
	
	const uint RETRY_COUNT = 10;
	const uint RETRY_INTERVAL = 60;
	
	public string appid { get; set; default = "0123456789abcdef0123456789abcdef"; }
	public string language { get; set; default = "de"; }
	
	public LocationProvider location {
		get {
			return this._location;
		}
		set {
			if(this.update_handler_id > 0) this._location.disconnect(this.update_handler_id);
			this._location = value;
			this.update_handler_id = this.location.update.connect( () => {this.async_refresh.begin();} );
		}
	}
	private LocationProvider _location;
	
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
	private uint _refresh_interval = 1800;
	
	private uint timeout = 0;
	private ulong update_handler_id = 0;
	private bool refresh_running = false;
	
	private JsonWrapper.Node? weather = null;
	
	public signal void update();
	
	construct {
		this.location = new StaticLocationProvider();
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
	
	public JsonWrapper.Node? get_weather() {
		return this.weather;
	}
	
	public async void async_refresh() {
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
	
	public async void refresh() throws Error {
		debug("Starting refresh");
		
		LocationInfo? location = this.location.get_location();
		if(location == null) return;
		
		Soup.Session ses = new Soup.Session();
		ses.proxy_resolver = null;
		ses.ssl_strict = false;
		ses.tls_database = null;
		
		Soup.URI uri = new Soup.URI(OWM_API);
		HashTable<string,string> query = new HashTable<string,string>(str_hash, null);
		
		query.insert("lat",location.lat.to_string());
		query.insert("lon",location.lng.to_string());
		query.insert("units","metric");
		query.insert("lang","de");
		query.insert("appid",this.appid);
		
		uri.set_query_from_form( query );
		
		debug("Request URL %s", uri.to_string(false));
		Soup.Message msg = new Soup.Message.from_uri("GET", uri);
		InputStream input = yield ses.send_async(msg);
		
		if(msg.status_code != 200) throw new IOError.FAILED("Got status code: %u: %s\n", msg.status_code, msg.reason_phrase);
		
		uint8[] data = new uint8[4096];
		size_t data_length;
		yield input.read_all_async(data, Priority.DEFAULT_IDLE, null, out data_length);
		
		this.weather = new JsonWrapper.Node.from_json_string( (string) data[0:data_length] );
		
		debug("Finished refresh");
		this.update();
	}
}
