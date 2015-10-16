using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Buzzer : GLib.Object {
	const uint8 PWM_PORT = 2;
	const uint8 PWM_CHIP = 0;
	
	const string PWM_PATH_EXPORT = "/sys/class/pwm/pwmchip%u/export";
	const string PWM_PATH_PERIOD = "/sys/class/pwm/pwmchip%u/pwm%u/period";
	const string PWM_PATH_DUTY_CYCLE = "/sys/class/pwm/pwmchip%u/pwm%u/duty_cycle";
	const string PWM_PATH_ENABLE = "/sys/class/pwm/pwmchip%u/pwm%u/enable";
	
	private static int buzzer;
	
	public static void beep( uint16 msec = 250, uint16 freq = 2000, uint8 volume = 255 ) {
		lock(buzzer) {
			try {
				GLib.File file;
				GLib.FileOutputStream ostream;
				GLib.DataOutputStream dostream;
				
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
					dostream.put_string("%u\n".printf(((1000000000/freq/2)*volume)/256));
				} catch( IOError e ) {
					// if duty_cycle > period, try the other way round
					if( e is IOError.INVALID_ARGUMENT ) {
						file = GLib.File.new_for_path( PWM_PATH_DUTY_CYCLE.printf(PWM_CHIP,PWM_PORT) );
						ostream = file.append_to(FileCreateFlags.NONE);
						dostream = new GLib.DataOutputStream( ostream );
						dostream.put_string("%u\n".printf(((1000000000/freq/2)*volume)/256));
						
						file = GLib.File.new_for_path( PWM_PATH_PERIOD.printf(PWM_CHIP,PWM_PORT) );
						ostream = file.append_to(FileCreateFlags.NONE);
						dostream = new GLib.DataOutputStream( ostream );
						dostream.put_string("%u\n".printf(1000000000/freq));
					}else{
						throw e;
					}
				}
				
				file = GLib.File.new_for_path( PWM_PATH_ENABLE.printf(PWM_CHIP,PWM_PORT) );
				ostream = file.append_to(FileCreateFlags.NONE);
				dostream = new GLib.DataOutputStream( ostream );
				dostream.put_string("%u\n".printf(1));
				
				Posix.usleep(msec*1000);
				
				file = GLib.File.new_for_path( PWM_PATH_ENABLE.printf(PWM_CHIP,PWM_PORT) );
				ostream = file.append_to(FileCreateFlags.NONE);
				dostream = new GLib.DataOutputStream( ostream );
				dostream.put_string("%u\n".printf(0));
			} catch( Error e ) {
				stderr.printf("Error: %s", e.message);
			}
		}
	}
} 