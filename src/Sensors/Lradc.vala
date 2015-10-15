using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Lradc : GLib.Object {
	const uint8 LRADC_DEVICE = 0;
	const string LRADC_PATH = "/sys/bus/iio/devices/iio:device%u/in_%s_%s";
	
	private static float temp_scale = float.NAN;
	private static float temp_offset = float.NAN;
	
	public static float read( string name, string type = "raw" ) {
		name.canon("abcdefghijklmnopqrstuvwxyz0123456789",'-');
		float value = 0;
		
		try {
			var file = GLib.File.new_for_path( LRADC_PATH.printf(LRADC_DEVICE,name,type) );
			var istream = file.read();
			var dis = new GLib.DataInputStream( istream );
			dis.read_line().scanf("%f\n",&value);
		} catch( Error e ) {
			stderr.printf("Error: %s", e.message);
		}
		return value;
	}
	
	public static float get_vdd5v() {
		return read("voltage15") / 4096f * 1.85f * 4f;
	}
	
	public static float get_vddio() {
		return read("voltage6") / 4096f * 1.85f * 2f;
	}
	
	public static float get_battery() {
		return read("voltage7") / 4096f * 1.85f * 4f;
	}
	
	public static float get_temp() {
		if(!temp_scale.is_normal()) {
			temp_scale = read("temp8","scale");
		}
		if(!temp_offset.is_normal()) {
			temp_offset = read("temp8","offset");
		}
		return (read("temp8") + temp_offset) * temp_scale;
	}
	
	public static float get_brightness() {
		return read("voltage1") / 4095;
	}
}
