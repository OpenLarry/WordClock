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
	
	public uint msec { get; set; default = 250; }
	public uint freq { get; set; default = 2000; }
	public uint8 volume { get; set; default = 255; }
	
	private class BuzzerCommand : GLib.Object {
		public enum Type {
			BEEP,
			PAUSE,
			EXIT
		}
		
		public Type cmd { get; private set; }
		public uint16 msec { get; private set; }
		public uint16 freq { get; private set; }
		public uint8 volume { get; private set; }
		
		public BuzzerCommand( BuzzerCommand.Type cmd, uint16 msec = 0, uint16 freq = 0, uint8 volume = 0 ) {
			this.cmd = cmd;
			this.msec = msec;
			this.freq = freq;
			this.volume = volume;
		}
	}
	
	private static AsyncQueue<BuzzerCommand> queue;
	private static Thread<bool>? thread = null;
	
	public void action () {
		beep( (uint16) this.msec, (uint16) this.freq, this.volume );
	}
	
	/**
	 * Start Buzzer thread
	 */
	public static void init() {
		if(thread != null) return;
		
		queue = new AsyncQueue<BuzzerCommand>();
		thread = new Thread<bool>("Buzzer", worker_thread);
	}
	
	/**
	 * Join Buzzer thread
	 */
	public static void deinit() {
		if(thread != null) {
			queue.push(new BuzzerCommand(BuzzerCommand.Type.EXIT));
			thread.join();
			thread = null;
		}
	}
	
	/**
	 * Receives and executes BuzzerCommands
	 */
	private static bool worker_thread() {
		BuzzerCommand cmd;
		while(true) {
			cmd = queue.pop();
			
			switch(cmd.cmd) {
				case BuzzerCommand.Type.BEEP:
					beep(cmd.msec, cmd.freq, cmd.volume);
					break;
				case BuzzerCommand.Type.PAUSE:
					pause(cmd.msec);
					break;
				case BuzzerCommand.Type.EXIT:
					return true;
			}
		}
	}
	
	/**
	 * Generates beep sound
	 * @param msec length
	 * @param freq frequency (Hz)
	 * @param volume volume (0-255)
	 */
	public static void beep( uint16 msec = 250, uint16 freq = 2000, uint8 volume = 255 ) {
		if(thread == null) return;
		
		if(Thread.self<bool>() != thread) {
			queue.push(new BuzzerCommand(BuzzerCommand.Type.BEEP, msec, freq, volume));
			return;
		}
		
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
	
	/**
	 * Generates pause
	 * @param msec length
	 */
	public static void pause( uint16 msec = 250 ) {
		if(thread == null) return;
		
		if(Thread.self<bool>() != thread) {
			queue.push(new BuzzerCommand(BuzzerCommand.Type.PAUSE, msec));
			return;
		}
		
		Thread.usleep(msec*1000);
	}
	
	public static void play_happy_birthday() {
		uint16 speed = 500;
		Buzzer.beep(speed / 2, 261);
		Buzzer.beep(speed / 2, 261);
		Buzzer.beep(speed, 293);
		Buzzer.beep(speed, 261);
		Buzzer.beep(speed, 349);
		Buzzer.beep(speed, 329);
		Buzzer.pause(speed);

		Buzzer.beep(speed / 2, 261);
		Buzzer.beep(speed / 2, 261);
		Buzzer.beep(speed, 293);
		Buzzer.beep(speed, 261);
		Buzzer.beep(speed, 392);
		Buzzer.beep(speed, 349);
		Buzzer.pause(speed);

		Buzzer.beep(speed / 2, 261);
		Buzzer.beep(speed / 2, 261);
		Buzzer.beep(speed, 523);
		Buzzer.beep(speed, 440);
		Buzzer.beep(speed / 2, 349);
		Buzzer.beep(speed / 2, 349);
		Buzzer.beep(speed, 329);
		Buzzer.beep(speed, 293);
		Buzzer.pause(speed);

		Buzzer.beep(speed / 2, 466);
		Buzzer.beep(speed / 2, 466);
		Buzzer.beep(speed, 440);
		Buzzer.beep(speed, 349);
		Buzzer.beep(speed, 392);
		Buzzer.beep(speed, 349);
		Buzzer.pause(speed);
		Buzzer.pause(speed);
	}
} 