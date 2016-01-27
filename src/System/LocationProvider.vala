using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.LocationProvider : GLib.Object, Jsonable {
	public signal void update();
	public abstract LocationInfo? get_location();
}

// container class
public class WordClock.LocationInfo : GLib.Object, Jsonable {
	public uint accuracy { get; set; default = uint.MAX; }
	public double lat { get; set; default = 0; }
	public double lng { get; set; default = 0; }
	
	public LocationInfo(double lat, double lng, uint accuracy = uint.MAX) {
		this.lat = lat;
		this.lng = lng;
		this.accuracy = accuracy;
	}
	
	public LocationInfo clone() {
		return new LocationInfo(this.lat,this.lng,this.accuracy);
	}
	
	public bool equals( LocationInfo other ) {
		return Math.fabs(this.lat - other.lat) < 0.00001 && Math.fabs(this.lng - other.lng) < 0.00001;
	}
}
