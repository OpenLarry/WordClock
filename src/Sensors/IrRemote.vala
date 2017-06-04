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
			if(repetition_number==0) this.action(interpreted_key_code);
		});
	}
}
