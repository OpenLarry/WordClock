using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.VariantMapper : GLib.Object {
	public static bool settings_get_mapping( ref GLib.Value value, GLib.Variant variant, void* user_data ) {
		TreeSet<string> settings_paths = new TreeSet<string>();
		
		for(int i=0;i<variant.n_children();i++) {
			string path;
			variant.get_child(i, "o", out path);
			settings_paths.add(path);
		}
		
		value.set_object( settings_paths );
		
		return true;
	}
	public static GLib.Variant settings_set_mapping( GLib.Value value, GLib.VariantType expected_type, void* user_data ) {
		TreeSet<string> settings_paths = (TreeSet<string>) value.get_object();
		
		Variant[] paths = {};
		foreach(string path in settings_paths) {
			paths += new Variant.object_path(path);
		}
		
		return new Variant.array( VariantType.OBJECT_PATH, paths );
	}
	
	
	public static bool color_get_mapping( ref GLib.Value value, GLib.Variant variant, void* user_data ) {
		uint16 h=0;
		uint8 s=0,v=0;
		variant.get_child(0, "q", out h);
		variant.get_child(1, "y", out s);
		variant.get_child(2, "y", out v);
		
		value.set_object( new Color.from_hsv(h%360,s,v) );
		
		return true;
	}
	public static GLib.Variant color_set_mapping( GLib.Value value, GLib.VariantType expected_type, void* user_data ) {
		Color color = (Color) value.get_object();
		
		uint16[] hsv = color.get_hsv();
		return new GLib.Variant.tuple( { new GLib.Variant.uint16( hsv[0] ), new GLib.Variant.byte( (uint8) hsv[1] ), new GLib.Variant.byte( (uint8) hsv[2] ) } );
	}
}
