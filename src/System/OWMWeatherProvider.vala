using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.OWMWeatherProvider : GLib.Object, Jsonable {
	const string OWM_API = "http://api.openweathermap.org/data/2.5/weather";
	const string OWM_APPID = "44db6a862fba0b067b1930da0d769e98";
	
	const uint RETRY_COUNT = 10;
	const uint RETRY_INTERVAL = 60;
	
	public string language { get; set; default = "de"; }
	
	public LocationProvider location {
		get {
			return this._location;
		}
		set {
			if(this.update_handler_id > 0) this._location.disconnect(this.update_handler_id);
			this._location = value;
			this.update_handler_id = this.location.update.connect( this.threaded_refresh );
		}
		default = new StaticLocationProvider();
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
	
	private OWMWeatherInfo? weather = null;
	
	public signal void update();
	
	construct {
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
	
	public OWMWeatherInfo? get_weather() {
		return this.weather;
	}
	
	public void threaded_refresh() {
		if(this.refresh_running) return;
		
		this.refresh_running = true;
		new Thread<int>("owmweather", () => {
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
		LocationInfo? location = this.location.get_location();
		if(location == null) return;
		
		Soup.Session ses = new Soup.SessionSync();
		Soup.URI uri = new Soup.URI(OWM_API);
		HashTable<string,string> query = new HashTable<string,string>(str_hash, null);
		
		query.insert("lat",location.lat.to_string());
		query.insert("lon",location.lng.to_string());
		query.insert("units","metric");
		query.insert("lang","de");
		query.insert("appid",OWM_APPID);
		
		uri.set_query_from_form( query );
		Soup.Request req = ses.request_uri( uri );
		
		DataInputStream dis = new DataInputStream( req.send() );
		string? line;
		string res = "";
		while ((line = dis.read_line ()) != null) {
			res += line;
		}
		
		OWMWeatherInfo weather = new OWMWeatherInfo();
		Json.Node node = JsonHelper.from_string( res );
		
		// properties named "type" are not allowed in the gobject system
		if(node.get_node_type() != Json.NodeType.OBJECT || !node.get_object().has_member("sys")) return;
		node.get_object().get_object_member("sys").remove_member("type");
		
		weather.from_json( node );
		this.weather = weather;
		this.update();
	}
}

// container classes
public class WordClock.OWMWeatherInfo : GLib.Object, Jsonable {
	public OWMWeatherCoord coord { get; set; default = new OWMWeatherCoord(); }
	public JsonableArrayList<OWMWeatherDetail> weather { get; set; default = new JsonableArrayList<OWMWeatherDetail>(); }
	public string base { get; set; default = ""; }
	public OWMWeatherMain main { get; set; default = new OWMWeatherMain(); }
	public OWMWeatherWind wind { get; set; default = new OWMWeatherWind(); }
	public OWMWeatherClouds clouds { get; set; default = new OWMWeatherClouds(); }
	// workaround because vala does not support properties with beginning numbers
	public JsonableTreeMap<JsonableNode> rain { get; set; default = new JsonableTreeMap<JsonableNode>(); }
	// workaround because vala does not support properties with beginning numbers
	public JsonableTreeMap<JsonableNode> snow { get; set; default = new JsonableTreeMap<JsonableNode>(); }
	public OWMWeatherVisibility visibility { get; set; default = new OWMWeatherVisibility(); }
	public int dt { get; set; default = 0; }
	public OWMWeatherSys sys { get; set; default = new OWMWeatherSys(); }
	public int id { get; set; default = 0; }
	public string name { get; set; default = ""; }
	public int cod { get; set; default = 0; }
}
public class WordClock.OWMWeatherCoord : GLib.Object, Jsonable {
	public double lon { get; set; default = 0; }
	public double lat { get; set; default = 0; }
}
public class WordClock.OWMWeatherDetail : GLib.Object, Jsonable {
	public int id { get; set; default = 0; }
	public string main { get; set; default = ""; }
	public string description { get; set; default = ""; }
	public string icon { get; set; default = ""; }
}
public class WordClock.OWMWeatherMain : GLib.Object, Jsonable {
	public double temp { get; set; default = 0; }
	public int pressure { get; set; default = 0; }
	public int humidity { get; set; default = 0; }
	public double temp_min { get; set; default = 0; }
	public double temp_max { get; set; default = 0; }
	public int sea_level { get; set; default = 0; }
	public int grnd_level { get; set; default = 0; }
}
public class WordClock.OWMWeatherWind : GLib.Object, Jsonable {
	public double speed { get; set; default = 0; }
	public int deg { get; set; default = 0; }
	public double gust { get; set; default = 0; }
}
public class WordClock.OWMWeatherClouds : GLib.Object, Jsonable {
	public int all { get; set; default = 0; }
}
public class WordClock.OWMWeatherVisibility : GLib.Object, Jsonable {
	public int distance { get; set; default = 0; }
	public int prefix { get; set; default = 0; }
}
public class WordClock.OWMWeatherSys : GLib.Object, Jsonable {
	public int id { get; set; default = 0; }
	public double message { get; set; default = 0; }
	public string country { get; set; default = ""; }
	public int sunrise { get; set; default = 0; }
	public int sunset { get; set; default = 0; }
}
