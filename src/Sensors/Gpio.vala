using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 *
 * https://www.linux.com/learn/tutorials/765810-beaglebone-black-how-to-get-interrupts-through-linux-gpio
 */
public class WordClock.Gpio : GLib.Object, SignalSource, Jsonable {
	const string GPIO_EXPORT = "/sys/class/gpio/export";
	
	const string GPIO_DIRECTION = "/sys/class/gpio/gpio%u/direction";
	const string GPIO_EDGE = "/sys/class/gpio/gpio%u/edge";
	const string GPIO_VALUE = "/sys/class/gpio/gpio%u/value";
	
	public bool value { get; set; default = false; }
	
	private bool first = true;
	
	public Gpio( uint8 pin ) {
		try {
			var file = GLib.File.new_for_path( GPIO_DIRECTION.printf(pin) );
			GLib.FileOutputStream ostream;
			try{
				ostream = file.append_to(FileCreateFlags.NONE);
			} catch( IOError e ) {
				if( e is IOError.NOT_FOUND ) {
					var dos = new GLib.DataOutputStream( GLib.File.new_for_path( GPIO_EXPORT ).append_to(FileCreateFlags.NONE) );
					dos.put_string("%u\n".printf(pin));
					
					ostream = file.append_to(FileCreateFlags.NONE);
				}else{
					throw e;
				}
			}
			var dostream = new GLib.DataOutputStream( ostream );
			dostream.put_string("in\n");
			
			file = GLib.File.new_for_path( GPIO_EDGE.printf(pin) );
			ostream = file.append_to(FileCreateFlags.NONE);
			dostream = new GLib.DataOutputStream( ostream );
			dostream.put_string("both\n");
			
			var channel = new IOChannel.file(GPIO_VALUE.printf(pin), "r");
			
			uint stat = channel.add_watch(IOCondition.PRI, (source,condition) => {
				size_t terminator_pos = -1;
				string str_return = null;
				size_t length = -1;

				if (condition == IOCondition.HUP) {
					warning("The connection has been broken");
					return Source.REMOVE;
				}

				try {
					source.seek_position(0, SeekType.SET);
					IOStatus status = source.read_line (out str_return, out length, out terminator_pos);
					if (status == IOStatus.EOF) {
						warning("Unexpected EOF");
						return Source.REMOVE;
					}
					
					this.value = str_return == "1\n";
					
					// don't fire signal after initializiation
					if(!this.first) {
						this.action((this.value)?"1":"0");
					}else{
						this.first = false;
					}
					
					return Source.CONTINUE;
				} catch (IOChannelError e) {
					warning("IOChannelError: %s", e.message);
					return Source.REMOVE;
				} catch (ConvertError e) {
					warning("ConvertError: %s", e.message);
					return Source.REMOVE;
				}
			});
			
			if(stat == 0) {
				warning("Cannot add watch on IOChannel");
			}
		} catch( Error e ) {
			warning(e.message);
		}
	}
}
