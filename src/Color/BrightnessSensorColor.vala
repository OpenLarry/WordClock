using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.BrightnessSensorColor : Color, Jsonable {
	public float min_brightness { get; set; default = 0f; }
	public float max_brightness { get; set; default = 1850f; }
	public Color min_color { get; set; default = new Color.from_hsv( 0, 0, 0 ); }
	public Color max_color { get; set; default = new Color.from_hsv( 0, 0, 255 ); }
	
	private uint8 actual_alpha = 0;
	private float brightness = 0;
	const int8 MAX_ALPHA_DIFF = 5;
	
	construct {
		Main.hwinfo.lradcs["brightness"].update.connect( this.update_brightness );
	}
	
	private void update_brightness() {
		this.brightness = Main.hwinfo.lradcs["brightness"].median;
	}
	
	protected override void update(uint framediff) {
		uint8 alpha = this.calc_alpha(this.brightness);
		
		// clip to in16 range
		if(framediff > 255/MAX_ALPHA_DIFF) framediff = 255/MAX_ALPHA_DIFF + 1;
		
		int16 diff = alpha - this.actual_alpha;
		diff = diff.clamp( -MAX_ALPHA_DIFF*(int16) framediff, MAX_ALPHA_DIFF*(int16) framediff );
		this.actual_alpha += (int8) diff;
		
		this.mix_with( this.min_color.clone().mix_with( this.max_color, this.actual_alpha ), 255 );
	}
	
	private uint8 calc_alpha( float brightness ) {
		if(brightness >= this.max_brightness) {
			return 255;
		}else if(brightness <= this.min_brightness) {
			return 0;
		}else{
			return (uint8) Math.roundf((brightness-this.min_brightness)*255/(this.max_brightness-this.min_brightness));
		}
	}
	
	public override Json.Node to_json( string path = "" ) throws JsonError {
		return Jsonable.default_to_json( this, path );
	}
	
	public override void from_json(Json.Node node, string path = "") throws JsonError {
		Jsonable.default_from_json( this, node, path );
	}
}
