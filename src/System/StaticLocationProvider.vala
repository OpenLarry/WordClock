using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.StaticLocationProvider : GLib.Object, Jsonable, LocationProvider {
	const string IWLIST = "iwlist wlan0 scan";
	const string GOOGLE_LOCATION_API = "https://maps.googleapis.com/maps/api/browserlocation/json";
	
	public LocationInfo location {
		get {
			return this._location;
		}
		set {
			if(this._location != value) {
				if(this.update_handler_id > 0) this._location.disconnect(this.update_handler_id);
				this._location = value;
				this.update_handler_id = this.location.notify.connect( this.check_for_change );
				this.check_for_change();
			}
		}
		default = new LocationInfo(0,0);
	}
	private LocationInfo? _location;
	private LocationInfo? old_location;
	
	private uint timeout = 0;
	private ulong update_handler_id = 0;
	
	protected void check_for_change() {
		if( this._location == null ) return;
		if( this.old_location == null || !this._location.equals( this.old_location ) ) {
			if(this.timeout > 0) GLib.Source.remove(this.timeout);
			this.timeout = GLib.Timeout.add(1000, () => {
				this.timeout = 0;
				this.update();
				return GLib.Source.REMOVE;
			});
			
			this.old_location = this._location.clone();
		}
	}
	
	public LocationInfo? get_location() {
		return this.location;
	}
}

