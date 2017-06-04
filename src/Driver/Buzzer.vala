using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Buzzer : GLib.Object, Jsonable, SignalSink {
	const uint8 PWM_PORT = 2;
	const uint8 PWM_CHIP = 0;
	
	const string PWM_PATH_EXPORT = "/sys/class/pwm/pwmchip%u/export";
	const string PWM_PATH_PERIOD = "/sys/class/pwm/pwmchip%u/pwm%u/period";
	const string PWM_PATH_DUTY_CYCLE = "/sys/class/pwm/pwmchip%u/pwm%u/duty_cycle";
	const string PWM_PATH_ENABLE = "/sys/class/pwm/pwmchip%u/pwm%u/enable";
	
	private static int buzzer;
	
	public uint msec { get; set; default = 250; }
	public uint freq { get; set; default = 2000; }
	public uint8 volume { get; set; default = 255; }
	
	public void action () {
		beep( (uint16) this.msec, (uint16) this.freq, this.volume );
	}
	
	/**
	 * Generates beep sound
	 * @param msec length
	 * @param freq frequency (Hz)
	 * @param volume volume (0-255)
	 */
	public static void beep( uint16 msec = 250, uint16 freq = 2000, uint8 volume = 255 ) {
		lock(buzzer) {
			try {
				GLib.File file;
				GLib.FileOutputStream ostream;
				GLib.DataOutputStream dostream;
				
				// set period and duty cycle (frequency and volume)
				try{
					file = GLib.File.new_for_path( PWM_PATH_PERIOD.printf(PWM_CHIP,PWM_PORT) );
					ostream = file.append_to(FileCreateFlags.NONE);
				} catch( IOError e ) {
					// if file not found -> export pwm output
					if( e is IOError.NOT_FOUND ) {
						dostream = new GLib.DataOutputStream( GLib.File.new_for_path( PWM_PATH_EXPORT.printf(PWM_CHIP) ).append_to(FileCreateFlags.NONE) );
						dostream.put_string("%u\n".printf(PWM_PORT));
						
						ostream = file.append_to(FileCreateFlags.NONE);
					}else{
						throw e;
					}
				}
				
				try{
					dostream = new GLib.DataOutputStream( ostream );
					dostream.put_string("%u\n".printf(1000000000/freq)); // fails if duty_cycle > period
					
					file = GLib.File.new_for_path( PWM_PATH_DUTY_CYCLE.printf(PWM_CHIP,PWM_PORT) );
					ostream = file.append_to(FileCreateFlags.NONE);
					dostream = new GLib.DataOutputStream( ostream );
					dostream.put_string("%u\n".printf(((1000000000/freq/2)*volume)/255));
				} catch( IOError e ) {
					// if duty_cycle > period, try the other way round
					if( e is IOError.INVALID_ARGUMENT ) {
						file = GLib.File.new_for_path( PWM_PATH_DUTY_CYCLE.printf(PWM_CHIP,PWM_PORT) );
						ostream = file.append_to(FileCreateFlags.NONE);
						dostream = new GLib.DataOutputStream( ostream );
						dostream.put_string("%u\n".printf(((1000000000/freq/2)*volume)/255));
						
						file = GLib.File.new_for_path( PWM_PATH_PERIOD.printf(PWM_CHIP,PWM_PORT) );
						ostream = file.append_to(FileCreateFlags.NONE);
						dostream = new GLib.DataOutputStream( ostream );
						dostream.put_string("%u\n".printf(1000000000/freq));
					}else{
						throw e;
					}
				}
				
				// enable
				file = GLib.File.new_for_path( PWM_PATH_ENABLE.printf(PWM_CHIP,PWM_PORT) );
				ostream = file.append_to(FileCreateFlags.NONE);
				dostream = new GLib.DataOutputStream( ostream );
				dostream.put_string("%u\n".printf(1));
				
				Thread.usleep(msec*1000);
				
				// disable
				file = GLib.File.new_for_path( PWM_PATH_ENABLE.printf(PWM_CHIP,PWM_PORT) );
				ostream = file.append_to(FileCreateFlags.NONE);
				dostream = new GLib.DataOutputStream( ostream );
				dostream.put_string("%u\n".printf(0));
			} catch( Error e ) {
				warning(e.message);
			}
		}
	}
	
	public static void play_happy_birthday() {
		uint16 speed = 500;
		Buzzer.beep(speed / 2, 261); 
		Buzzer.beep(speed / 2, 261); 
		Buzzer.beep(speed, 293); 
		Buzzer.beep(speed, 261); 
		Buzzer.beep(speed, 349); 
		Buzzer.beep(speed, 329); 
		Thread.usleep(speed*1000); 

		Buzzer.beep(speed / 2, 261); 
		Buzzer.beep(speed / 2, 261); 
		Buzzer.beep(speed, 293); 
		Buzzer.beep(speed, 261); 
		Buzzer.beep(speed, 392); 
		Buzzer.beep(speed, 349); 
		Thread.usleep(speed*1000); 

		Buzzer.beep(speed / 2, 261); 
		Buzzer.beep(speed / 2, 261); 
		Buzzer.beep(speed, 523); 
		Buzzer.beep(speed, 440); 
		Buzzer.beep(speed / 2, 349); 
		Buzzer.beep(speed / 2, 349); 
		Buzzer.beep(speed, 329); 
		Buzzer.beep(speed, 293); 
		Thread.usleep(speed*1000); 

		Buzzer.beep(speed / 2, 466); 
		Buzzer.beep(speed / 2, 466); 
		Buzzer.beep(speed, 440); 
		Buzzer.beep(speed, 349); 
		Buzzer.beep(speed, 392); 
		Buzzer.beep(speed, 349); 
		Thread.usleep(speed*1000); 
		Thread.usleep(speed*1000);
	}
} 