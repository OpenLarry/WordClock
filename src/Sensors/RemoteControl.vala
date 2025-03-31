using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.RemoteControl : GLib.Object, SignalSource {
	const string INPUT_DEVICE = "gpio-ir-receiver";
	const string INPUT_EVENT = "/dev/input/event0";
	const string INPUT_PROTOCOLS = "/sys/devices/soc0/%s/rc/rc0/protocols";

	public class Key : GLib.Object {
		public string name;
		public uint8[] scancode;

		public Key( string name, uint8[] scancode ) {
			this.name = name;
			this.scancode = scancode;
		}
	}
	
	private ArrayList<Key> keys = new ArrayList<Key>();
	private IOChannel channel;
	private uint8 repetition = 0;
	
	public RemoteControl( string[] protocols ) {
		try {
			// enable protocols
			var dos = new GLib.DataOutputStream( GLib.File.new_for_path( INPUT_PROTOCOLS.printf(INPUT_DEVICE) ).append_to(FileCreateFlags.NONE) );
			
			dos.put_string("none\n");
			foreach( string protocol in protocols ) {
				dos.put_string("+%s\n".printf(protocol));
			}

			this.channel = new IOChannel.file(INPUT_EVENT, "r");
			this.channel.set_encoding(null);

			// delete scancodes
			Linux.Input.KeymapEntry entry = {};
			do {
				entry.flags = 1;
				entry.keycode = Linux.Input.KEY_RESERVED;
				entry.index = 0;
			}
			while ( Linux.ioctl(this.channel.unix_get_fd(), Linux.Input.EVIOCSKEYCODE_V2, &entry) == 0 );
			
			uint stat = this.channel.add_watch(IOCondition.IN, receive);
			
			if(stat == 0) {
				warning("Cannot add watch on IOChannel");
			}
		} catch( Error e ) {
			warning(e.message);
		}
	}

	public void add_key( Key key ) {
		Linux.Input.KeymapEntry entry = {};
		entry.flags = 0;
		entry.keycode = Linux.Input.BTN_TRIGGER_HAPPY + this.keys.size;
		entry.len = (uint8) key.scancode.length;
		entry.scancode = key.scancode;
		
		assert(Linux.ioctl(this.channel.unix_get_fd(), Linux.Input.EVIOCSKEYCODE_V2, &entry) == 0);
		this.keys.add(key);
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

			if(ev.type == Linux.Input.EV_KEY && ev.value > 0) {
				uint16 key = (uint16) (ev.code - Linux.Input.BTN_TRIGGER_HAPPY);
				bool handled = false;
				
				if(ev.value == 1) {
					this.repetition = 0;
					handled = this.action(this.keys[key].name);
				} else {
					this.repetition++;
					handled = this.action(this.keys[key].name+"-"+this.repetition.to_string());
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
