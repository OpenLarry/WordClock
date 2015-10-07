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
	
	
	public Buzzer( ) {
		try {
			var file = GLib.File.new_for_path( PWM_PATH_EXPORT.printf(PWM_CHIP) );
			var ostream = file.append_to(FileCreateFlags.NONE);
			var dostream = new GLib.DataOutputStream( ostream );
			dostream.put_string("%u\n".printf(PWM_PORT));
		} catch( Error e ) {
			// ignore error if pwm port is already exported
		}
	}
	
	
	public void beep( uint16 freq, uint8 volume, uint16 msec ) {
		try {
			var file = GLib.File.new_for_path( PWM_PATH_PERIOD.printf(PWM_CHIP,PWM_PORT) );
			var ostream = file.append_to(FileCreateFlags.NONE);
			var dostream = new GLib.DataOutputStream( ostream );
			dostream.put_string("%u\n".printf(1000000000/freq));
			
			file = GLib.File.new_for_path( PWM_PATH_DUTY_CYCLE.printf(PWM_CHIP,PWM_PORT) );
			ostream = file.append_to(FileCreateFlags.NONE);
			dostream = new GLib.DataOutputStream( ostream );
			dostream.put_string("%u\n".printf(((1000000000/freq/2)*volume)/256));
			
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