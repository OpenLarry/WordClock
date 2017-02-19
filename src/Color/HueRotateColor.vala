using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.HueRotateColor : Color, Jsonable {
	public uint timespan { get; set; default = 60; }
	public Color basic_color { get; set; default = new Color.from_hsv( 0, 0, 0 ); }
	
	protected override void update(uint framediff) {
		this.hue_by_time( new DateTime.now(Main.timezone) );
	}
	
	private void hue_by_time( DateTime time ) {
		uint seconds = time.get_hour() * 60 * 60 + time.get_minute() * 60 + time.get_second();
		
		uint offset = 0;
		if( (360/this.timespan) > 1 ) {
			offset = 360 * time.get_microsecond() / this.timespan / 1000000;
		}
		
		this.mix_with( this.basic_color, 255 );
		uint16 hue = this.basic_color.get_hsv()[0];
		hue = (hue + (int16) (((seconds%this.timespan) * 360)/this.timespan + offset)) % 360;
		
		this.set_hsv( hue, null, null );
	}
	
	public override Json.Node to_json( string path = "" ) throws JsonError {
		return Jsonable.default_to_json( this, path );
	}
	
	public override void from_json(Json.Node node, string path = "") throws JsonError {
		Jsonable.default_from_json( this, node, path );
	}
}
