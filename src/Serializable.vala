using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.Serializable : GLib.Object, Json.Serializable {
	// workaround for multiple inheritance
	// https://wiki.gnome.org/Projects/Vala/Tutorial#Mixins_and_Multiple_Inheritance
	public static Json.Node serialize_property(Serializable that, string property_name, Value value, ParamSpec pspec) {
		if(pspec.value_type.is_a(typeof(TreeSet)) && that.get_class().get_type().is_a(typeof(Settings)) && property_name == "settings-paths") {
			return Json.gvariant_serialize( VariantMapper.settings_set_mapping( value, new VariantType("*"), null ) );
		}else if(pspec.value_type.is_a(typeof(Color))) {
			return Json.gvariant_serialize( VariantMapper.color_set_mapping( value, new VariantType("*"), null ) );
		}else{
			return that.default_serialize_property( property_name, value, pspec );
		}
	}
	public static bool deserialize_property(Serializable that, string property_name, out Value value, ParamSpec pspec, Json.Node property_node) {
		value = Value(pspec.value_type);
		
		try{
			if(pspec.value_type.is_a(typeof(TreeSet)) && that.get_class().get_type().is_a(typeof(Settings)) && property_name == "settings-paths") {
				return VariantMapper.settings_get_mapping( ref value, Json.gvariant_deserialize(property_node, null), null );
			}else if(pspec.value_type.is_a(typeof(Color))) {
				return VariantMapper.color_get_mapping( ref value, Json.gvariant_deserialize(property_node, "(qyy)"), null );
			}else{
				// Usually "ref value" instead of "&value" should be the right parameter
				// but due to the wrong implementation of Json.Serializable.default_deserialize_property() (missing "out" or "ref" keyword)
				// passing value by c-reference is the only working solution
				return that.default_deserialize_property(property_name, &value, pspec, property_node);
			}
		} catch ( Error e ) {
			stderr.printf("gvariant_deserialize: %s\n", e.message);
			return false;
		}
	}
	public static unowned ParamSpec find_property(Serializable that, string name) {
		return that.get_class().find_property(name);
	}
}
