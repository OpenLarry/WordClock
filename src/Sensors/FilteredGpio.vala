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
	
	public FilteredGpio( Gpio gpio ) {
		this.gpio = gpio;
		this.gpio.action.connect(this.check_time);
	}
	
	private void check_time(string action) {
		if(action == "1") {
			timer_0.stop();
			timer_1.start();
			if(this.min_low_time > 0 && timer_0.elapsed() >= this.min_low_time) this.action("0");
		}else if(action == "0") {
			timer_1.stop();
			timer_0.start();
			if(this.min_high_time > 0 && timer_1.elapsed() >= this.min_high_time) this.action("1");
		}
	}
}
