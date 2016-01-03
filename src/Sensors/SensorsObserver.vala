using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.SensorsObserver : GLib.Object, Jsonable, SignalSource {
	private Sensors sensors;
	
	public JsonableTreeMap<SensorsThreshold> thresholds { get; set; default = new JsonableTreeMap<SensorsThreshold>(); }
	
	
	public SensorsObserver( Sensors sensors, uint interval = 1000 ) {
		this.sensors = sensors;
		
		GLib.Timeout.add(interval, () => {
			this.check();
			return true;
		});
	}
	
	public void check() {
		this.thresholds.foreach((entry) => {
			ParamSpec? pspec = this.sensors.get_class().find_property( entry.key );
			if(pspec == null) {
				stderr.printf("Property does not exist!\n");
				return true;
			}
			
			Value val = Value( pspec.value_type );
			
			this.sensors.get_property( entry.key, ref val );
			
			bool? action = entry.value.check( val.get_float() );
			if(action != null) {
				this.action( entry.key+((action)?"-higher":"-lower") );
			}
			
			return true;
		});
	}
	
	public class SensorsThreshold : GLib.Object, Jsonable {
		public double threshold { get; set; default = 0; }
		public double hysteresis { get; set; default = 0; }
		public bool first { get; set; default = false; }
		
		public bool? old_state = null;
		
		public bool? check ( double val ) {
			bool? new_state = null;
			
			if( val - this.threshold > this.hysteresis / 2 ) new_state = true;
			else if( this.threshold - val > this.hysteresis / 2 ) new_state = false;
			
			if(new_state != null) {
				if((this.old_state != null || this.first) && this.old_state != new_state) {
					this.old_state = new_state;
					return new_state;
				}else{
					this.old_state = new_state;
					return null;
				}
			}else{
				return null;
			}
		}
	}
}
