using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.BigTimeRenderer : GLib.Object, ClockRenderable, MatrixRenderer, SettingsBindable {
	public Color background_color { get; set; default = new Color.from_hsv( 0, 0, 0 ); }
	public Color hours_color { get; set; default = new Color.from_hsv( 100, 255, 150 ); }
	public Color minutes_color { get; set; default = new Color.from_hsv( 140, 255, 150 ); }
	
	protected GLib.Settings settings;
	
	private uint16[] NUMBERS_35 = {
		0x7B6F, 0x1749, 0x73E7, 0x73CF, 0x5BC9, 0x79CF, 0x79EF, 0x7292, 0x7BEF, 0x7BCF, 
	};
	
	/**
	 * Renders time
	 * @param leds Array of LED RGB values
	 * @return Continue
	 */
	public bool render_matrix( Color[,] leds_matrix ) {
		for(int i=0;i<leds_matrix.length[0];i++) {
			for(int j=0;j<leds_matrix.length[1];j++) {
				leds_matrix[i,j].mix_with(this.background_color, 255);
			}
		}
		
		var time = new DateTime.now_local();
		
		render_number(leds_matrix, (uint8) time.get_hour()/10, 2, 0, this.hours_color);
		render_number(leds_matrix, (uint8) time.get_hour()%10, 6, 0, this.hours_color);
		render_number(leds_matrix, (uint8) time.get_minute()/10, 2, 5, this.minutes_color);
		render_number(leds_matrix, (uint8) time.get_minute()%10, 6, 5, this.minutes_color);
		
		return true;
	}
	
	public void render_number( Color[,] leds_matrix, uint8 number, uint8 x, uint8 y, Color color ){
		for(int8 i = 14;i>=0;i--) {
			if((bool) NUMBERS_35[number] & 1 << i) {
				int _x = x+(2-i%3);
				int _y = y+(4-i/3);
				if(_x < 0 || _x > 10 || _y < 0 || _y > 9) continue;
				leds_matrix[ _x, _y ].mix_with(color, 255); 
			}
		}
	}
	
	public void bind_settings(GLib.SettingsSchemaSource sss, string name) {
		GLib.SettingsSchema schema = sss.lookup ("de.wordclock.renderer.bigtime", false);
		if (sss.lookup == null) {
			stderr.printf ("ID not found.");
			return;
		}
		
		name.canon("abcdefghijklmnopqrstuvwxyz-",'-');
		
		this.settings = new GLib.Settings.full (schema, null, "/de/wordclock/renderer/bigtime/"+name+"/");
		
		this.settings.bind_with_mapping("background-color", this, "background_color", GLib.SettingsBindFlags.DEFAULT,(SettingsBindGetMappingShared) Color.get_mapping,(SettingsBindSetMappingShared) Color.set_mapping, null, null);
		this.settings.bind_with_mapping("hours-color", this, "hours_color", GLib.SettingsBindFlags.DEFAULT,(SettingsBindGetMappingShared) Color.get_mapping,(SettingsBindSetMappingShared) Color.set_mapping, null, null);
		this.settings.bind_with_mapping("minutes-color", this, "minutes_color", GLib.SettingsBindFlags.DEFAULT,(SettingsBindGetMappingShared) Color.get_mapping,(SettingsBindSetMappingShared) Color.set_mapping, null, null);
	}
	
	public void unbind_settings() {;
		GLib.Settings.unbind(this, "background_color");
		GLib.Settings.unbind(this, "hours_color");
		GLib.Settings.unbind(this, "minutes_color");
	}
}
