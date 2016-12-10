using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.CpuLoad : GLib.Object, Jsonable, SystemSensor {
	const string CPU_STAT = "/proc/stat";
	
	private uint8 dataPos = 0;
	private int64[] sum = new int64[2];
	private int64[] data = new int64[14];
	
	public float user {
		get {
			return ((float) (data[0] - data[7]).abs()) / (sum[0] - sum[1]).abs();
		}
	}
	public float nice {
		get {
			return ((float) (data[1] - data[8]).abs()) / (sum[0] - sum[1]).abs();
		}
	}
	public float system {
		get {
			return ((float) (data[2] - data[9]).abs()) / (sum[0] - sum[1]).abs();
		}
	}
	public float idle {
		get {
			return ((float) (data[3] - data[10]).abs()) / (sum[0] - sum[1]).abs();
		}
	}
	public float iowait {
		get {
			return ((float) (data[4] - data[11]).abs()) / (sum[0] - sum[1]).abs();
		}
	}
	public float irq {
		get {
			return ((float) (data[5] - data[12]).abs()) / (sum[0] - sum[1]).abs();
		}
	}
	public float softirq {
		get {
			return ((float) (data[6] - data[13]).abs()) / (sum[0] - sum[1]).abs();
		}
	}
	
	public CpuLoad( uint interval = 2) {
		GLib.Timeout.add_seconds(interval, () => {
			// ignore timeout if no other reference is held anymore
			if(this.ref_count == 1) return GLib.Source.REMOVE;
			
			this.read();
			return GLib.Source.CONTINUE;
		});
		this.read();
	}
	
	public void read() {
		try {
			var file = GLib.File.new_for_path(CPU_STAT);
			var dis = new GLib.DataInputStream( file.read() );
			
			int i = dataPos++;
			dataPos %= 2;
			
			dis.read_line().scanf(
				"cpu  %ld %ld %ld %ld %ld %ld %ld",
				out this.data[i*7+0],
				out this.data[i*7+1],
				out this.data[i*7+2],
				out this.data[i*7+3],
				out this.data[i*7+4],
				out this.data[i*7+5],
				out this.data[i*7+6]
			);
			
			sum[i] = this.data[i*7+0]+this.data[i*7+1]+this.data[i*7+2]+this.data[i*7+3]+this.data[i*7+4]+this.data[i*7+5]+this.data[i*7+6];
			
			if(sum[0] > 0 && sum[1] > 0) this.update();
		} catch( Error e ) {
			stderr.printf("Error: %s", e.message);
		}
	}
}
