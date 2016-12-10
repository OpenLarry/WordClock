using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.MemoryUsage : GLib.Object, Jsonable, SystemSensor {
	const string MEM = "/proc/meminfo";
	
	public uint total { get; private set; default = 0; }
	public uint free { get; private set; default = 0; }
	public uint available { get; private set; default = 0; }
	public uint buffers { get; private set; default = 0; }
	public uint cached { get; private set; default = 0; }
	
	public MemoryUsage( uint interval = 5) {
		GLib.Timeout.add_seconds(interval, () => {
			this.read();
			return GLib.Source.CONTINUE;
		});
		this.read();
	}
	
	public void read() {
		try {
			var file = GLib.File.new_for_path(MEM);
			var dis = new GLib.DataInputStream( file.read() );
			
			uint val = 0;
			dis.read_line().scanf("MemTotal:%*20[ ]%u", out val);
			this.total = val;
			
			dis.read_line().scanf("MemFree:%*20[ ]%u", out val);
			this.free = val;
			
			dis.read_line().scanf("MemAvailable:%*20[ ]%u", out val);
			this.available = val;
			
			dis.read_line().scanf("Buffers:%*20[ ]%u", out val);
			this.buffers = val;
			
			dis.read_line().scanf("Cached:%*20[ ]%u", out val);
			this.cached = val;
			
			this.update();
		} catch( Error e ) {
			stderr.printf("Error: %s", e.message);
		}
	}
}
