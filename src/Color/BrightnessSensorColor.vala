using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.BrightnessSensorColor : Color, Jsonable {
	public float min_brightness { get; set; default = 0f; }
	public float max_brightness { get; set; default = 1f; }
	public Color min_color { get; set; default = new Color.from_hsv( 0, 0, 0 ); }
	public Color max_color { get; set; default = new Color.from_hsv( 0, 0, 255 ); }
	
	construct {
		Main.sensors.updated.connect( this.update );
	}
	
	private void update() {
		float brightness = Main.sensors.brightness_median;
		if(brightness >= this.max_brightness) {
			this.mix_with( this.max_color, 255 );
		}else if(brightness <= this.min_brightness) {
			this.mix_with( this.min_color, 255 );
		}else{
			this.mix_with( this.min_color.clone().mix_with( this.max_color, (uint8) Math.roundf((brightness-this.min_brightness)*255/(this.max_brightness-this.min_brightness)) ), 255 );
		}
	}
	
	public override Json.Node to_json( string path = "" ) throws JsonError {
		return Jsonable.default_to_json( this, path );
	}
	
	public override void from_json(Json.Node node, string path = "") throws JsonError {
		Jsonable.default_from_json( this, node, path );
		this.update();
	}
}
