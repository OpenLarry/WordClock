using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Color : GLib.Object, Jsonable {
	/* MUST NOT BE MODIFIED, fields are public for performance reasons ! */
	public uint8 r = 0;
	public uint8 g = 0;
	public uint8 b = 0;
	
	protected uint8 r_no_gamma = 0;
	protected uint8 g_no_gamma = 0;
	protected uint8 b_no_gamma = 0;
	
	protected uint16 h = 0;
	protected uint8  s = 0;
	protected uint8  v = 0;
	
	private static uint8[] gamma_correction = {};
	
	const double GAMMA = 2.2;
	
	// init gamma correction
	static construct {
		gamma_correction = new uint8[256];
		for(uint16 i=0;i<256;i++) {
			gamma_correction[i] = (uint8) Math.round(Math.pow(i/255.0,GAMMA)*255);
		}
	}
	
	/**
	 * Create a new instance for representing any colors
	 * @param h Color hue
	 * @param s Color saturation
	 * @param v Color value (brightness)
	 */
	public Color.from_hsv( uint16 h, uint8 s, uint8 v ) {
		this.set_hsv(h,s,v);
	}
	
	/**
	 * Create a new instance for representing any colors
	 * @param r Red channel brightness
	 * @param g Green channel brightness
	 * @param b Blue channel brightness
	 */
	public Color.from_rgb( uint8 r, uint8 g, uint8 b ) {
		this.set_rgb(r,g,b);
	}
	
	public Color set_hsv( uint16? h, uint8? s, uint8? v ) {
		this.h = h ?? this.h;
		this.h = this.h % 360;
		this.s = s ?? this.s;
		this.v = v ?? this.v;
		
		this.to_rgb();
		this.do_gamma_correction();
		return this;
	}
	
	public Color set_rgb( uint8? r, uint8? g, uint8? b ) {
		this.r_no_gamma = r ?? this.r_no_gamma;
		this.g_no_gamma = g ?? this.g_no_gamma;
		this.b_no_gamma = b ?? this.b_no_gamma;
		
		this.to_hsv();
		this.do_gamma_correction();
		return this;
	}
	
	public uint16[] get_hsv( ) {
		return { this.h, this.s, this.v };
	}
	
	public uint8[] get_rgb( ) {
		return { this.r_no_gamma, this.g_no_gamma, this.b_no_gamma };
	}
	
	/**
	 * Convert rgb to hsv values
	 * http://stackoverflow.com/a/14733008
	 */
	protected void to_hsv() {
		uint8 rgbMin, rgbMax;

		rgbMin = uint8.min(this.r_no_gamma,uint8.min(this.g_no_gamma,this.b_no_gamma));
		rgbMax = uint8.max(this.r_no_gamma,uint8.max(this.g_no_gamma,this.b_no_gamma));

		this.v = rgbMax;
		if (this.v == 0) {
			this.h = 0;
			this.s = 0;
			return;
		}

		this.s = (uint8) (((uint16) 255) * (rgbMax - rgbMin) / this.v);
		if (this.s == 0) {
			this.h = 0;
			return;
		}

		if (rgbMax == this.r_no_gamma) {
			this.h = 0 + 60 * (this.g_no_gamma - this.b_no_gamma) / (rgbMax - rgbMin);
		}else if (rgbMax == this.g_no_gamma) {
			this.h = 120 + 60 * (this.b_no_gamma - this.r_no_gamma) / (rgbMax - rgbMin);
		}else{
			this.h = 240 + 60 * (this.r_no_gamma - this.g_no_gamma) / (rgbMax - rgbMin);
		}
	}
	
	/**
	 * Convert hsv to rgb values
	 * http://stackoverflow.com/a/14733008
	 */
	protected void to_rgb() {
		uint8 region, fpart, p, q, t;
		
		if(this.s == 0) {
			this.r_no_gamma = this.g_no_gamma = this.b_no_gamma = v;
			return;
		}
		
		region = this.h / 60;
		fpart = (this.h - (region * 60)) * 4;
		
		p = (this.v * (255 - this.s)) >> 8;
		q = (this.v * (255 - ((this.s * fpart) >> 8))) >> 8;
		t = (this.v * (255 - ((this.s * (255 - fpart)) >> 8))) >> 8;
			
		switch(region) {
			case 0:
				this.r_no_gamma = this.v; this.g_no_gamma = t; this.b_no_gamma = p; break;
			case 1:
				this.r_no_gamma = q; this.g_no_gamma = this.v; this.b_no_gamma = p; break;
			case 2:
				this.r_no_gamma = p; this.g_no_gamma = this.v; this.b_no_gamma = t; break;
			case 3:
				this.r_no_gamma = p; this.g_no_gamma = q; this.b_no_gamma = this.v; break;
			case 4:
				this.r_no_gamma = t; this.g_no_gamma = p; this.b_no_gamma = this.v; break;
			default:
				this.r_no_gamma = this.v; this.g_no_gamma = p; this.b_no_gamma = q; break;
		}
		
		return;
	}
	
	/**
	 * Mixes this color with another, allows daisy chaining
	 * @param color The other color
	 * @param percent Mixing factor between 0 (this color) and 255 (param color)
	 * @return this color
	 */
	public Color mix_with( Color color, uint8 percent = 127, bool gamma_fade = true ) {
		if(percent == 0) {
			return this;
		}else if(percent == 255) {
			this.r = color.r;
			this.g = color.g;
			this.b = color.b;
			this.r_no_gamma = color.r_no_gamma;
			this.g_no_gamma = color.g_no_gamma;
			this.b_no_gamma = color.b_no_gamma;
			this.h = color.h;
			this.s = color.s;
			this.v = color.v;
		}else if(gamma_fade) {
			this.r_no_gamma = (uint8) ( (((uint16) this.r_no_gamma)*(255-percent) + ((uint16) color.r_no_gamma)*percent) / 255 );
			this.g_no_gamma = (uint8) ( (((uint16) this.g_no_gamma)*(255-percent) + ((uint16) color.g_no_gamma)*percent) / 255 );
			this.b_no_gamma = (uint8) ( (((uint16) this.b_no_gamma)*(255-percent) + ((uint16) color.b_no_gamma)*percent) / 255 );
			this.do_gamma_correction();
		}else{
			this.r = (uint8) ( (((uint16) this.r)*(255-percent) + ((uint16) color.r)*percent) / 255 );
			this.g = (uint8) ( (((uint16) this.g)*(255-percent) + ((uint16) color.g)*percent) / 255 );
			this.b = (uint8) ( (((uint16) this.b)*(255-percent) + ((uint16) color.b)*percent) / 255 );
		}
		
		return this;
	}
	
	public Color clone() {
		var ret = new Color();
		
		ret.r = this.r;
		ret.g = this.g;
		ret.b = this.b;
		ret.r_no_gamma = this.r_no_gamma;
		ret.g_no_gamma = this.g_no_gamma;
		ret.b_no_gamma = this.b_no_gamma;
		ret.h = this.h;
		ret.s = this.s;
		ret.v = this.v;
		
		return ret;
	}
	
	protected void do_gamma_correction() {
		this.r = gamma_correction[this.r_no_gamma];
		this.g = gamma_correction[this.g_no_gamma];
		this.b = gamma_correction[this.b_no_gamma];
	}
	
	public virtual Json.Node to_json( string path = "" ) throws JsonError {
		string subpath;
		string? property = JsonHelper.get_property( path, out subpath );
		
		if(property != null) {
			if(subpath!="") throw new JsonError.INVALID_PATH("Invalid path '%s'!".printf(subpath));
			
			Json.Node node = new Json.Node( Json.NodeType.VALUE );
			switch(property) {
				case "h":
					node.set_int( this.h );
				break;
				case "s":
					node.set_int( this.s );
				break;
				case "v":
					node.set_int( this.v );
				break;
				default:
					throw new JsonError.INVALID_PATH("Invalid property '%s'!".printf(property));
			}
			return node;
		}else{
			Json.Object obj = new Json.Object();
			
			obj.set_int_member( "h", this.h );
			obj.set_int_member( "s", this.s );
			obj.set_int_member( "v", this.v );
			
			Json.Node node = new Json.Node( Json.NodeType.OBJECT );
			node.take_object(obj);
			
			return node;
		}
	}
	
	public virtual void from_json(Json.Node node, string path = "") throws JsonError {
		string subpath;
		string? property = JsonHelper.get_property( path, out subpath );
		
		if(property != null) {
			if(subpath!="") throw new JsonError.INVALID_PATH("Invalid path '%s'!".printf(subpath));
			if( node.get_node_type() != Json.NodeType.VALUE ) throw new JsonError.INVALID_NODE_TYPE("Invalid node type! Value expected.");
			
			switch(property) {
				case "h":
					this.set_hsv( (uint16) node.get_int(), null, null );
				break;
				case "s":
					this.set_hsv( null, (uint8) node.get_int(), null );
				break;
				case "v":
					this.set_hsv( null, null, (uint8) node.get_int() );
				break;
				default:
					throw new JsonError.INVALID_PATH("Invalid property '%s'!".printf(property));
			}
		}else{
			if( node.get_node_type() != Json.NodeType.OBJECT ) throw new JsonError.INVALID_NODE_TYPE("Invalid node type! Object expected.");
			
			Json.Object obj = node.get_object();
			if(
				obj.has_member("h") && obj.get_member("h").get_node_type() != Json.NodeType.VALUE ||
				obj.has_member("s") && obj.get_member("s").get_node_type() != Json.NodeType.VALUE ||
				obj.has_member("v") && obj.get_member("v").get_node_type() != Json.NodeType.VALUE
			) throw new JsonError.INVALID_NODE_TYPE("Invalid node type! Value expected.");
			
			uint16? h = null;
			uint8? s = null, v = null;
			if(obj.has_member("h")) h = (uint16) obj.get_int_member( "h" );
			if(obj.has_member("s")) s = (uint8) obj.get_int_member( "s" );
			if(obj.has_member("v")) v = (uint8) obj.get_int_member( "v" );
			
			this.set_hsv(h,s,v);
		}
	}
}
