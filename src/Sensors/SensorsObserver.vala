using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.SensorsObserver : GLib.Object, Jsonable, SignalSource {
	private Sensors sensors;
	
	public JsonableTreeMap<JsonableNode> thresholds { get; set; default = new JsonableTreeMap<JsonableNode>(); }
	
	public TreeMap<string,bool> states = new TreeMap<string,bool>();
	
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
			
			if( !val.holds(typeof(float)) || entry.value.node.get_node_type() != Json.NodeType.VALUE || !entry.value.node.get_value_type().is_a(typeof(double)) ) {
				stderr.printf("Incompatible types!\n");
				return true;
			}
			
			this.sensors.get_property( entry.key, ref val );
			
			if(this.states.has_key( entry.key )) {
				bool old_state = this.states[entry.key];
				bool new_state = val.get_float() > entry.value.node.get_double();
				if(old_state != new_state) {
					this.action( entry.key+((new_state)?"_higher":"_lower") );
					this.states[entry.key] = new_state;
				}
			}else{
				this.states[entry.key] = val.get_float() > entry.value.node.get_double();;
			}
			
			return true;
		});
	}
}
