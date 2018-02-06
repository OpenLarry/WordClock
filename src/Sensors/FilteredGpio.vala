using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.FilteredGpio : GLib.Object , SignalSource, Jsonable {
	public double min_high_time { get; set; default = 0.05; }
	public double min_low_time { get; set; default = -1; }
	
	private Gpio gpio;
	private Timer timer_0 = new Timer();
	private Timer timer_1 = new Timer();
	private bool? last = null;
	
	public FilteredGpio( Gpio gpio ) {
		this.gpio = gpio;
		this.gpio.action.connect(this.check_time);
	}
	
	private bool check_time(string action) {
		if(action == "0") timer_0.start();
		if(action == "1") timer_1.start();
		
		if(action == "0" && last == true && this.min_high_time > 0 && timer_1.elapsed() >= this.min_high_time) {
			this.last = (action == "1");
			return this.action("1");
		}
		if(action == "1" && last == false && this.min_low_time > 0 && timer_0.elapsed() >= this.min_low_time) {
			this.last = (action == "1");
			return this.action("0");
		}
		
		this.last = (action == "1");
		return false;
	}
}
