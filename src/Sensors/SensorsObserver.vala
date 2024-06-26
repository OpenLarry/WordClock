using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.SensorsObserver : GLib.Object, Jsonable, SignalSource {
	private HardwareInfo hwinfo;
	
	public JsonableTreeMap<SensorsThreshold> thresholds { get; set; default = new JsonableTreeMap<SensorsThreshold>(); }
	
	
	public SensorsObserver( HardwareInfo hwinfo, uint interval = 1 ) {
		this.hwinfo = hwinfo;
		
		GLib.Timeout.add_seconds(interval, () => {
			// ignore timeout if no other reference is held anymore
			if(this.ref_count == 1) return GLib.Source.REMOVE;
			
			this.check();
			return GLib.Source.CONTINUE;
		});
	}
	
	public void check() {
		this.thresholds.foreach((entry) => {
			string[] parts = entry.key.split("-");
			
			if(parts.length != 2 || !this.hwinfo.lradcs.has_key(parts[0])) {
				warning("Lradc channel does not exist");
				return true;
			}
			
			Lradc lradc = this.hwinfo.lradcs[parts[0]];
			
			ParamSpec? pspec = lradc.get_class().find_property(parts[1]);
			if(pspec == null) {
				warning("Lradc property does not exist");
				return true;
			}
			
			Value val = Value( pspec.value_type );
			
			lradc.get_property( parts[1], ref val );
			
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
