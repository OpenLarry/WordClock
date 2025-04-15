using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.RemoteControl : DevInput {
	const string INPUT_PROTOCOLS = "/sys/devices/soc0/%s/rc/rc0/protocols";
	
	public RemoteControl( string eventDevice, string irDevice, string[] protocols ) {
		try {
			base(eventDevice);
			
			// enable protocols
			var dos = new GLib.DataOutputStream( GLib.File.new_for_path( INPUT_PROTOCOLS.printf(irDevice) ).append_to(FileCreateFlags.NONE) );
			
			dos.put_string("none\n");
			foreach( string protocol in protocols ) {
				dos.put_string("+%s\n".printf(protocol));
			}

			// delete scancodes
			Linux.Input.KeymapEntry entry = {};
			do {
				entry.flags = 1;
				entry.keycode = Linux.Input.KEY_RESERVED;
				entry.index = 0;
			}
			while ( Linux.ioctl(this.channel.unix_get_fd(), Linux.Input.EVIOCSKEYCODE_V2, &entry) == 0 );

		} catch( Error e ) {
			warning(e.message);
		}
	}

	public void add_scancode( string name, uint8[] scancode ) {
		Linux.Input.KeymapEntry entry = {};
		entry.flags = 0;
		entry.keycode = Linux.Input.BTN_TRIGGER_HAPPY + this.codes.size;
		entry.len = (uint8) scancode.length;
		entry.scancode = scancode;
		
		assert(Linux.ioctl(this.channel.unix_get_fd(), Linux.Input.EVIOCSKEYCODE_V2, &entry) == 0);
		this.add_code( name, entry.keycode );
	}
}
