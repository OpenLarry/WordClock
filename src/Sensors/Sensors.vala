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
	
	public float vdd5v {
		get { return mean(this.vdd5v_vals); }
	}
	public float vddio {
		get { return mean(this.vddio_vals); }
	}
	public float battery {
		get { return mean(this.battery_vals); }
	}
	public float temp {
		get { return mean(this.temp_vals); }
	}
	public float brightness {
		get { return mean(this.brightness_vals); }
	}
	
	public bool motion { get; set; }
	public bool button0 { get; set; }
	public bool button1 { get; set; }
	public bool button2 { get; set; }
	
	const uint8 SIZE = 10;
	
	private static float mean(LinkedList<float?> list) {
		float? sum = list.fold<float?>( (a,b) => { return a+b; }, 0f );
		if(sum == null || list.size == 0) {
			return 0;
		}else{
			return sum / list.size;
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
		
		this.motion = Main.pir.value;
		this.button0 = Main.button0.value;
		this.button1 = Main.button1.value;
		this.button2 = Main.button2.value;
	}
}
