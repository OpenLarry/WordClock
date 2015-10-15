using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public struct WordClock.Sensors {
	public float vdd5v;
	public float vddio;
	public float battery;
	public float temp;
	public float brightness;
	public bool motion;
	
	public static Json.Node serialize_func (void* _boxed) {
		assert (_boxed != null);

		Sensors* boxed = (Sensors*) _boxed;

		Json.Node node = new Json.Node(Json.NodeType.OBJECT);
		Json.Object obj = new Json.Object ();
		obj.set_double_member("vdd5v", boxed.vdd5v);
		obj.set_double_member("vddio", boxed.vddio);
		obj.set_double_member("battery", boxed.battery);
		obj.set_double_member("temp", boxed.temp);
		obj.set_double_member("brightness", boxed.brightness);
		obj.set_boolean_member("motion", boxed.motion);
		node.set_object (obj);
		return node;
	}
	
	public static Sensors get_readings() {
		return { Lradc.get_vdd5v(), Lradc.get_vddio(), Lradc.get_battery(), Lradc.get_temp(), Lradc.get_brightness(), false };
	}
}