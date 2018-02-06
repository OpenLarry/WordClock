using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 *
 * https://www.linux.com/learn/tutorials/765810-beaglebone-black-how-to-get-interrupts-through-linux-gpio
 */
public class WordClock.IrRemote : GLib.Object, SignalSource {
	const string PROG = "wordclock-remote";
	
	private Lirc.Context context;
	private Lirc.Listener listener;
	
	public IrRemote( MainContext? loop_context = null ) {
		try{
			this.context = new Lirc.Context(PROG);
			this.listener = new Lirc.Listener(this.context, loop_context);
		} catch( Error e ) {
			warning(e.message);
			return;
		}
		
		this.listener.button.connect((device_conf, interpreted_key_code, repetition_number) => {
			bool handled = false;
			
			if(repetition_number==0) handled = this.action(device_conf+"-"+interpreted_key_code);
			else if(repetition_number%10==0) handled = this.action(device_conf+"-"+interpreted_key_code+"-"+repetition_number.to_string());
			
			if(handled) Buzzer.beep(50,2500,255);
		});
	}
}
