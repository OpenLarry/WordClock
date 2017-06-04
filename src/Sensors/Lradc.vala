using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 *
 * https://github.com/analogdevicesinc/libiio
 * https://pmeerw.net/blog/2012/Aug
 * http://www.at91.com/linux4sam/bin/view/Linux4SAM/IioAdcDriver
 */
public class WordClock.Lradc : GLib.Object, Jsonable {
	const uint8 LRADC_DEVICE = 0;
	const string LRADC_IIO_DEVICE = "/dev/iio:device%u";
	const string LRADC_PATH = "/sys/bus/iio/devices/iio:device%u/in_%s_%s";
	const string LRADC_SCAN_ELEMENTS = "/sys/bus/iio/devices/iio:device%u/scan_elements/in_%s_en";
	const string LRADC_CURRENT_TRIGGER = "/sys/bus/iio/devices/iio:device%u/trigger/current_trigger";
	const string LRADC_TRIGGER = "80050000.lradc-dev0";
	const string LRADC_BUFFER_WATERMARK = "/sys/bus/iio/devices/iio:device%u/buffer/watermark";
	const string LRADC_BUFFER_LENGTH = "/sys/bus/iio/devices/iio:device%u/buffer/length";
	const string LRADC_BUFFER_ENABLE = "/sys/bus/iio/devices/iio:device%u/buffer/enable";
	
	const uint8 TEMP_MIN = 8;
	const uint8 TEMP_MAX = 9;
	
	const uint8 HISTORY_SIZE = 60;
	
	const uint8 CHAN_COUNT = 16;
	
	private static TreeMap<uint8,Lradc> instances;
	
	private static bool running = false;
	
	
	private float scale = float.NAN;
	private float offset = float.NAN;
	
	public LinkedList<uint16?> values = new LinkedList<uint16?>();
	private uint8 chan;
	
	public signal void update();
	
	public float median {
		get {
			if(!this._median.is_normal()) {
				this._median = this.convert_value( Statistic.median( this.values ) );
			}
			
			return this._median;
		}
	}
	private float _median = float.NAN;
	
	public float mean {
		get {
			if(!this._mean.is_normal()) {
				this._mean = this.convert_value( Statistic.mean( this.values ) );
			}
			
			return this._mean;
		}
	}
	private float _mean = float.NAN;
	
	public float min {
		get {
			if(!this._min.is_normal()) {
				this._min = this.convert_value( Statistic.min( this.values ) );
			}
			
			return this._min;
		}
	}
	private float _min = float.NAN;
	
	public float max {
		get {
			if(!this._max.is_normal()) {
				this._max = this.convert_value( Statistic.max( this.values ) );
			}
			
			return this._max;
		}
	}
	private float _max = float.NAN;
	
	private Lradc(uint8 chan) {
		this.chan = chan;
	}
	
	/**
	 * ensure that buffer is disabled
	 */
	static construct {
		try {
			GLib.DataOutputStream dos;
			dos = new GLib.DataOutputStream( GLib.File.new_for_path( LRADC_BUFFER_ENABLE.printf(LRADC_DEVICE) ).append_to(FileCreateFlags.NONE) );
			dos.put_string("0\n");
		} catch( Error e ) {
			warning(e.message);
		}
	}
	
	public static Lradc? get_channel( uint8 chan ) {
		if(instances == null) instances = new TreeMap<uint8,Lradc>((a,b) => { return a-b; });
		
		if(chan == TEMP_MAX) chan = TEMP_MIN;
		
		if(!instances.has_key(chan)) {
			if(running) return null;
			instances[chan] = new Lradc( chan );
		}
		if(chan == TEMP_MIN) instances[TEMP_MAX] = instances[TEMP_MIN];
		
		return instances[chan];
	}
	
	public static void start() {
		if(running) return;
		
		running = true;
		try {
			var dos = new GLib.DataOutputStream( GLib.File.new_for_path( LRADC_BUFFER_LENGTH.printf(LRADC_DEVICE) ).append_to(FileCreateFlags.NONE) );
			dos.put_string("5\n");
			
			dos = new GLib.DataOutputStream( GLib.File.new_for_path( LRADC_BUFFER_WATERMARK.printf(LRADC_DEVICE) ).append_to(FileCreateFlags.NONE) );
			dos.put_string("1\n");
			
			dos = new GLib.DataOutputStream( GLib.File.new_for_path( LRADC_CURRENT_TRIGGER.printf(LRADC_DEVICE) ).append_to(FileCreateFlags.NONE) );
			dos.put_string("%s\n".printf(LRADC_TRIGGER));
			
			for(uint8 i=0;i<CHAN_COUNT;i++) {
				dos = new GLib.DataOutputStream( GLib.File.new_for_path( LRADC_SCAN_ELEMENTS.printf(LRADC_DEVICE,get_name(i)) ).append_to(FileCreateFlags.NONE) );
				dos.put_string(instances.has_key(i) ? "1\n" : "0\n");
			}
			
			dos = new GLib.DataOutputStream( GLib.File.new_for_path( LRADC_BUFFER_ENABLE.printf(LRADC_DEVICE) ).append_to(FileCreateFlags.NONE) );
			dos.put_string("1\n");
			
			var channel = new IOChannel.file(LRADC_IIO_DEVICE.printf(LRADC_DEVICE), "r");
			channel.set_encoding(null);
			
			uint stat = channel.add_watch(IOCondition.IN, receive);
			
			if(stat == 0) {
				warning("Cannot add watch on IOChannel");
			}
		} catch( Error e ) {
			warning(e.message);
		}
	}
	
	public static void stop() {
		if(!running) return;
		
		try {
			GLib.DataOutputStream dos;
			dos = new GLib.DataOutputStream( GLib.File.new_for_path( LRADC_BUFFER_ENABLE.printf(LRADC_DEVICE) ).append_to(FileCreateFlags.NONE) );
			dos.put_string("0\n");
			
			running = false;
		} catch( Error e ) {
			warning(e.message);
		}
	}
	
	private static string get_name(uint8 i) {
		switch(i) {
			case 8:
				return "temp8";
			default:
				return "voltage%u".printf(i);
		}
	}
	
	private void reset() {
		this._mean = float.NAN;
		this._median = float.NAN;
		this._min = float.NAN;
		this._max = float.NAN;
	}
	
	private static bool receive( IOChannel source, IOCondition condition ) {
		char[] buf = new char[instances.size*4];
		size_t length = -1;

		if (condition == IOCondition.HUP) {
			warning("The connection has been broken");
			return Source.REMOVE;
		}

		try {
			IOStatus status = source.read_chars(buf, out length);
			
			if (status == IOStatus.EOF) {
				warning("Unexpected EOF");
				return Source.REMOVE;
			}
			
			uint i=0;
			uint16 val = 0;
			foreach(Map.Entry<uint8,Lradc> entry in instances.entries) {
				if(entry.key == TEMP_MIN) {
					val = -(buf[i] | (buf[i+1] << 8));
				}else if(entry.key == TEMP_MAX) {
					val += buf[i] | (buf[i+1] << 8);
					entry.value.values.offer_tail(val);
					if(entry.value.values.size > HISTORY_SIZE) entry.value.values.poll_head();
					entry.value.reset();
					entry.value.update();
				}else{
					val = buf[i] | (buf[i+1] << 8);
					entry.value.values.offer_tail(val);
					if(entry.value.values.size > HISTORY_SIZE) entry.value.values.poll_head();
					entry.value.reset();
					entry.value.update();
				}
				
				i += 4;
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
	
	private float read( string type = "raw" ) throws Error {
		float value = 0;
	
		var file = GLib.File.new_for_path( LRADC_PATH.printf(LRADC_DEVICE,get_name(this.chan),type) );
		var istream = file.read();
		var dis = new GLib.DataInputStream( istream );
		dis.read_line().scanf("%f\n",&value);
		
		return value;
	}
	
	public bool set_scale( string scale ) {
		if(running) return false;
		
		try {
			var dos = new GLib.DataOutputStream( GLib.File.new_for_path( LRADC_PATH.printf(LRADC_DEVICE,get_name(this.chan),"scale") ).append_to(FileCreateFlags.NONE) );
			dos.put_string("%s\n".printf(scale));
			
			this.scale = float.NAN;
		} catch( Error e ) {
			warning(e.message);
			return false;
		}
		
		return true;
	}
	
	private float convert_value(uint16 val) {
		try{
			if(!this.offset.is_normal()) {
				this.offset = this.read("offset");
			}
		}catch( Error e) {
			// ignore error since only temp has an offset
			this.offset = 0;
		}
		
		try{
			if(!this.scale.is_normal()) {
				this.scale = this.read("scale");
			}
		}catch(Error e) {
			warning(e.message);
		}
		
		return (val + this.offset) * this.scale;
	}
}
