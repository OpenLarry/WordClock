using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.DevInput : GLib.Object, SignalSource {
	protected HashMap<uint32, string> codes = new HashMap<uint32, string>();
	protected IOChannel channel;
	private uint8 repetition = 0;
	
	public DevInput( string device ) {
		try {
			this.channel = new IOChannel.file(device, "r");
			this.channel.set_encoding(null);
			
			uint stat = this.channel.add_watch(IOCondition.IN, receive);
			
			if(stat == 0) {
				warning("Cannot add watch on IOChannel");
			}
		} catch( Error e ) {
			warning(e.message);
		}
	}

	public void add_code( string name, uint32 code, uint32 type = Linux.Input.EV_KEY ) {
		this.codes[(type << 16) | code] = name;
	}
	
	private bool receive( IOChannel source, IOCondition condition ) {
		if (condition == IOCondition.HUP) {
			warning("The connection has been broken");
			return Source.REMOVE;
		}

		try {
			Linux.Input.Event ev = {};
			size_t length = -1;
			IOStatus status = source.read_chars((char[]) &ev, out length);
			
			if (status == IOStatus.EOF) {
				warning("Unexpected EOF");
				return Source.REMOVE;
			}

			//  if(ev.type == Linux.Input.EV_MSC && ev.code == Linux.Input.MSC_SCAN) {
			//  	debug("Scanned key: %u, %u, %u, %u", ev.value & 0xFF, (ev.value >> 8) & 0xFF, (ev.value >> 16) & 0xFF, ev.value >> 24);
			//  }

			uint32 key = (ev.type << 16) | ev.code;
			if(this.codes.has_key(key)) {
				bool handled = false;
				
				if(ev.value == 1) {
					this.repetition = 0;
					handled = this.action(this.codes[key]);
				} else if (ev.value == 0) {
					handled = this.action(this.codes[key]+"-release");
				} else {
					this.repetition++;
					handled = this.action(this.codes[key]+"-"+this.repetition.to_string());
				}
				if(handled) Buzzer.beep(50,2500,255);
			}

			return Source.CONTINUE;
		} catch (IOChannelError e) {
			warning("IOChannelError: %s", e.message);
			return Source.REMOVE;
		} catch (ConvertError e) {
			warning("ConvertError: %s", e.message);
			return Source.REMOVE;
		}
	}
	
}
