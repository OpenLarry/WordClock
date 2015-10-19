using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Sensors : GLib.Object {
	private LinkedList<float?> vdd5v_vals = new LinkedList<float?>();
	private LinkedList<float?> vddio_vals = new LinkedList<float?>();
	private LinkedList<float?> battery_vals = new LinkedList<float?>();
	private LinkedList<float?> temp_vals = new LinkedList<float?>();
	private LinkedList<float?> brightness_vals = new LinkedList<float?>();
	
	public float vdd5v_mean {
		get { return mean(this.vdd5v_vals); }
	}
	public float vdd5v_min {
		get { return min(this.vdd5v_vals); }
	}
	public float vdd5v_max {
		get { return max(this.vdd5v_vals); }
	}
	public float vddio_mean {
		get { return mean(this.vddio_vals); }
	}
	public float vddio_min {
		get { return min(this.vddio_vals); }
	}
	public float vddio_max {
		get { return max(this.vddio_vals); }
	}
	public float battery_mean {
		get { return mean(this.battery_vals); }
	}
	public float battery_min {
		get { return min(this.battery_vals); }
	}
	public float battery_max {
		get { return max(this.battery_vals); }
	}
	public float temp_mean {
		get { return mean(this.temp_vals); }
	}
	public float temp_min {
		get { return min(this.temp_vals); }
	}
	public float temp_max {
		get { return max(this.temp_vals); }
	}
	public float brightness_mean {
		get { return mean(this.brightness_vals); }
	}
	public float brightness_min {
		get { return min(this.brightness_vals); }
	}
	public float brightness_max {
		get { return max(this.brightness_vals); }
	}
	
	public bool motion { get; private set; }
	public bool button0 { get; private set; }
	public bool button1 { get; private set; }
	public bool button2 { get; private set; }
	
	const uint8 SIZE = 20;
	
	private static float min(LinkedList<float?> list) {
		if(list.size == 0) {
			return float.NAN;
		}else{
			float? min = list.fold<float?>( (a,b) => { return (a<b) ? a : b; }, float.INFINITY );
			return min ?? float.NAN;
		}
	}
	
	private static float max(LinkedList<float?> list) {
		if(list.size == 0) {
			return float.NAN;
		}else{
			float? min = list.fold<float?>( (a,b) => { return (a>b) ? a : b; }, -float.INFINITY );
			return min ?? float.NAN;
		}
	}
	
	private static float mean(LinkedList<float?> list) {
		if(list.size == 0) {
			return float.NAN;
		}else{
			float? sum = list.fold<float?>( (a,b) => { return a+b; }, 0f );
			return (sum ?? float.NAN) / list.size;
		}
	}
	
	public void read() {
		this.vdd5v_vals.offer_tail( Lradc.get_vdd5v() );
		this.vddio_vals.offer_tail( Lradc.get_vddio() );
		this.battery_vals.offer_tail( Lradc.get_battery() );
		this.temp_vals.offer_tail( Lradc.get_temp() );
		this.brightness_vals.offer_tail( Lradc.get_brightness() );
		
		if(this.vdd5v_vals.size > SIZE) this.vdd5v_vals.poll_head();
		if(this.vddio_vals.size > SIZE) this.vddio_vals.poll_head();
		if(this.battery_vals.size > SIZE) this.battery_vals.poll_head();
		if(this.temp_vals.size > SIZE) this.temp_vals.poll_head();
		if(this.brightness_vals.size > SIZE) this.brightness_vals.poll_head();
		
		this.motion = Main.motion.value;
		this.button0 = Main.button0.value;
		this.button1 = Main.button1.value;
		this.button2 = Main.button2.value;
	}
}
