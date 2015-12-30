using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Sensors : GLib.Object, Jsonable {
	private LinkedList<float?> vdd5v_vals = new LinkedList<float?>();
	private LinkedList<float?> vddio_vals = new LinkedList<float?>();
	private LinkedList<float?> battery_vals = new LinkedList<float?>();
	private LinkedList<float?> temp_vals = new LinkedList<float?>();
	private LinkedList<float?> brightness_vals = new LinkedList<float?>();
	
	public signal void updated();
	
	public float vdd5v_median {
		get { return median(this.vdd5v_vals); }
	}
	public float vdd5v_mean {
		get { return mean(this.vdd5v_vals); }
	}
	public float vdd5v_min {
		get { return min(this.vdd5v_vals); }
	}
	public float vdd5v_max {
		get { return max(this.vdd5v_vals); }
	}
	public float vddio_median {
		get { return median(this.vddio_vals); }
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
	public float battery_median {
		get { return median(this.battery_vals); }
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
	public float temp_median {
		get { return median(this.temp_vals); }
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
	public float brightness_median {
		get { return median(this.brightness_vals); }
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
	public string iwconfig {
		owned get { 
			string output;
			try{
				Process.spawn_command_line_sync("iwconfig wlan0", out output);
			}catch( Error e ) {
				output = e.message;
			}
			return output; 
		}
	}
	
	public bool motion { get; set; }
	public bool button0 { get; set; }
	public bool button1 { get; set; }
	public bool button2 { get; set; }
	
	const uint8 SIZE = 60;
	
	public Sensors( uint interval = 500 ) {
		if(interval > 0) {
			GLib.Timeout.add(interval, () => {
				this.read();
				return true;
			});
		}
	}
	
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
	
	private static float median(LinkedList<float?> list) {
		if(list.size == 0) {
			return float.NAN;
		}else{
			ArrayList<float?> array = new ArrayList<float?>();
			array.add_all(list);
			array.sort((a,b) => {
				return (a<b) ? -1 : (a>b) ? 1 : 0;
			});
			
			if(list.size % 2 == 1) {
				return array[list.size/2];
			}else{
				return (array[list.size/2] + array[list.size/2-1]) / 2.0f;
			}
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
		
		this.updated();
	}
}
