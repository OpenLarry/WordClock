using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.ModifyColor : Color, Jsonable {
	public Color basic_color { get; set; default = new Color.from_hsv( 0, 0, 0 ); }
	public int add_h { get; set; default = 0; }
	public int add_s { get; set; default = 0; }
	public int add_v { get; set; default = 0; }
	public float multiply_s { get; set; default = 1; }
	public float multiply_v { get; set; default = 1; }
	
	protected override void update(uint framediff) {
		this.mix_with( this.basic_color, 255 );
		
		uint16 h;
		uint8 s, v;
		this.get_hsv( out h, out s, out v );
		
		h += 360 + this.add_h;
		s = (uint8) (this.add_s + multiply_s * s).clamp(uint8.MIN, uint8.MAX);
		v = (uint8) (this.add_v + multiply_v * v).clamp(uint8.MIN, uint8.MAX);
		
		this.set_hsv(h,s,v);
	}
	
	public override Json.Node to_json( string path = "" ) throws JsonError {
		return Jsonable.default_to_json( this, path );
	}
	
	public override void from_json(Json.Node node, string path = "") throws JsonError {
		Jsonable.default_from_json( this, node, path );
	}
}
