using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Color : GLib.Object, Jsonable {
	/* MUST NOT BE MODIFIED, fields are public for performance reasons ! */
	public uint16 r = 0;
	public uint16 g = 0;
	public uint16 b = 0;
	
	protected uint8 r_no_gamma = 0;
	protected uint8 g_no_gamma = 0;
	protected uint8 b_no_gamma = 0;
	
	protected uint16 h = 0;
	protected uint8  s = 0;
	protected uint8  v = 0;
	
	protected uint last_update_frame = uint.MAX;
	
	private static uint16[] gamma_correction = {};
	
	const double GAMMA = 2.2;
	
	// init gamma correction
	static construct {
		gamma_correction = new uint16[256];
		for(uint16 i=0;i<256;i++) {
			gamma_correction[i] = (uint16) Math.round(Math.pow(i/255.0,GAMMA)*65535);
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
		this.to_rgb_rainbow();
		return this;
	}
	
	public Color set_rgb( uint8? r, uint8? g, uint8? b ) {
		this.r_no_gamma = r ?? this.r_no_gamma;
		this.g_no_gamma = g ?? this.g_no_gamma;
		this.b_no_gamma = b ?? this.b_no_gamma;
		
		this.to_hsv();
		this.to_rgb_rainbow();
		return this;
	}
	
	public void get_hsv( out uint16 h, out uint8 s, out uint8 v, bool check_update = true ) {
		if(check_update) this.check_update();
		h = this.h;
		s = this.s;
		v = this.v;
	}
	
	public void get_rgb( out uint8 r, out uint8 g, out uint8 b, bool check_update = true ) {
		if(check_update) this.check_update();
		r = this.r_no_gamma;
		g = this.g_no_gamma;
		b = this.b_no_gamma;
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
	protected void to_hsv_gamma() {
		uint16 rgbMin, rgbMax;

		rgbMin = uint16.min(this.r,uint16.min(this.g,this.b));
		rgbMax = uint16.max(this.r,uint16.max(this.g,this.b));

        // invert gamma correction
        for(this.v=0;rgbMax>gamma_correction[this.v];this.v++);
        
		if (this.v == 0) {
			this.h = 0;
			this.s = 0;
			return;
		}

		this.s = (uint8) (((uint16) 255) * (rgbMax - rgbMin)/256 / this.v);
		if (this.s == 0) {
			this.h = 0;
			return;
		}

		if (rgbMax == this.r) {
			this.h = 0 + 60 * (this.g - this.b) / (rgbMax - rgbMin)/256;
		}else if (rgbMax == this.g) {
			this.h = 120 + 60 * (this.b - this.r) / (rgbMax - rgbMin)/256;
		}else{
			this.h = 240 + 60 * (this.r - this.g) / (rgbMax - rgbMin)/256;
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
	
	protected virtual void update(uint framediff) {}
	protected void check_update() {
		uint frame = (Main.hwinfo.system["leddriver"] as LedDriver).frame;
		if(this.last_update_frame != frame) {
			uint framediff = frame - this.last_update_frame;
			this.last_update_frame = frame;
			this.update(framediff);
		}
	}
	
	/**
	 * Mixes this color with another, allows daisy chaining
	 * @param color The other color
	 * @param percent Mixing factor between 0 (this color) and 255 (param color)
	 * @return this color
	 */
	public Color mix_with( Color color, uint8 percent = 127, bool gamma_fade = true ) {
		if(percent == 0) {
			this.check_update();
		}else if(percent == 255) {
			color.check_update();
			this.r = color.r;
			this.g = color.g;
			this.b = color.b;
			this.r_no_gamma = color.r_no_gamma;
			this.g_no_gamma = color.g_no_gamma;
			this.b_no_gamma = color.b_no_gamma;
			this.h = color.h;
			this.s = color.s;
			this.v = color.v;
			this.last_update_frame = color.last_update_frame;
		}else if(gamma_fade) {
			color.check_update();
			this.check_update();
			this.r_no_gamma = (uint8) ( (((uint16) this.r_no_gamma)*(255-percent) + ((uint16) color.r_no_gamma)*percent) / 255 );
			this.g_no_gamma = (uint8) ( (((uint16) this.g_no_gamma)*(255-percent) + ((uint16) color.g_no_gamma)*percent) / 255 );
			this.b_no_gamma = (uint8) ( (((uint16) this.b_no_gamma)*(255-percent) + ((uint16) color.b_no_gamma)*percent) / 255 );
			this.to_hsv();
            this.to_rgb_rainbow();
		}else{
			color.check_update();
			this.check_update();
			this.r = (uint16) ( (((uint) this.r)*(255-percent) + ((uint) color.r)*percent) / 255 );
			this.g = (uint16) ( (((uint) this.g)*(255-percent) + ((uint) color.g)*percent) / 255 );
			this.b = (uint16) ( (((uint) this.b)*(255-percent) + ((uint) color.b)*percent) / 255 );
			this.to_hsv_gamma();
            this.to_rgb();
		}
		
		return this;
	}
	
	/**
	 * Mixes this color with rgb values, allows daisy chaining
	 * @param r red
	 * @param g green
	 * @param b blue
	 * @param percent Mixing factor between 0 (this color) and 255 (param color)
	 * @return this color
	 */
	public Color mix_with_rgb( uint8 r, uint8 g, uint8 b, uint8 percent = 127 ) {
		if(percent == 0) {
			this.check_update();
		}else if(percent == 255) {
			this.set_rgb(r,g,b);
		}else{
			this.check_update();
			this.r_no_gamma = (uint8) ( (((uint16) this.r_no_gamma)*(255-percent) + ((uint16) r)*percent) / 255 );
			this.g_no_gamma = (uint8) ( (((uint16) this.g_no_gamma)*(255-percent) + ((uint16) g)*percent) / 255 );
			this.b_no_gamma = (uint8) ( (((uint16) this.b_no_gamma)*(255-percent) + ((uint16) b)*percent) / 255 );
			this.to_hsv();
			// this.do_gamma_correction();
            this.to_rgb_rainbow();
		}
		
		return this;
	}
	
	public Color clone() {
		this.check_update();
		
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
		
		ret.last_update_frame = this.last_update_frame;
		
		return ret;
	}
	
	public bool equal( Color other ) {
		this.check_update();
		other.check_update();
		return this.h == other.h && this.s == other.s && this.v == other.v;
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

	// The following functions are based on the FastLED hsv2rgb_rainbow conversion:
	// https://github.com/FastLED/FastLED/blob/9307a2926e66dd2d4707315057d1de7f2bb3ed0b/src/hsv2rgb.cpp#L251-L470
	// 
	// Background information:
	// https://github.com/FastLED/FastLED/wiki/FastLED-HSV-Colors
	// https://hackaday.com/2016/08/23/rgb-leds-how-to-master-gamma-and-hue-for-perfect-brightness/
	//
	// Adjusted to generate 16 bit rgb values

	/*
		The MIT License (MIT)

		Copyright (c) 2013 FastLED

		Permission is hereby granted, free of charge, to any person obtaining a copy of
		this software and associated documentation files (the "Software"), to deal in
		the Software without restriction, including without limitation the rights to
		use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
		the Software, and to permit persons to whom the Software is furnished to do so,
		subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
		FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
		COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
		IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
		CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	*/

	private static uint8 scale8( uint8 i, uint8 scale )
	{
		return (((uint16)i) * (1+(uint16)(scale))) >> 8;
	}

	private static uint16 scale16( uint16 i, uint16 scale )
	{
		return (uint16)((((uint32)i) * (1+(uint32)(scale))) >> 16);
	}

	private static uint8 scale8_video( uint8 i, uint8 scale )
	{
		return (uint8)((((int)i * (int)scale) >> 8) + ((i != 0 && scale != 0)?1:0));
	}

	private static uint16 scale16_video( uint16 i, uint16 scale )
	{
		return (uint16)((((uint32)i * (uint32)scale) >> 16) + ((i != 0 && scale != 0)?1:0));
	}

	protected void to_rgb_rainbow() {
		// Yellow has a higher inherent brightness than
		// any other color; 'pure' yellow is perceived to
		// be 93% as bright as white.  In order to make
		// yellow appear the correct relative brightness,
		// it has to be rendered brighter than all other
		// colors.
		// Level Y1 is a moderate boost, the default.
		// Level Y2 is a strong boost.
		const bool Y1 = true;
		const bool Y2 = false;
		
		// G2: Whether to divide all greens by two.
		// Depends GREATLY on your particular LEDs
		const bool G2 = false;
		
		// Gscale: what to scale green down by.
		// Depends GREATLY on your particular LEDs
		const uint8 Gscale = 0;

		uint8 hue = (uint8)(this.h * 256 / 360);
		uint8 sat = this.s;
		uint8 val = this.v;
		
		uint8 offset = hue & 0x1F; // 0..31
		
		// offset8 = offset * 8
		uint8 offset8 = offset;
		// On ARM and other non-AVR platforms, we just shift 3.
		offset8 <<= 3;
		
		uint8 third = scale8( offset8, (uint8)(256 / 3)); // max = 85
		
		uint8 r=0, g=0, b=0;
		
		if( (hue & 0x80) == 0 ) {
			// 0XX
			if( (hue & 0x40) == 0 ) {
				// 00X
				//section 0-1
				if( (hue & 0x20) == 0 ) {
					// 000
					//case 0: // R -> O
					r = 255 - third;
					g = third;
					b = 0;
				} else {
					// 001
					//case 1: // O -> Y
					if( Y1 ) {
						r = 171;
						g = 85 + third ;
						b = 0;
					}
					if( Y2 ) {
						r = 170 + third;
						//uint8 twothirds = (third << 1);
						uint8 twothirds = scale8( offset8, (uint8)((256 * 2) / 3)); // max=170
						g = 85 + twothirds;
						b = 0;
					}
				}
			} else {
				//01X
				// section 2-3
				if( (hue & 0x20) == 0 ) {
					// 010
					//case 2: // Y -> G
					if( Y1 ) {
						//uint8 twothirds = (third << 1);
						uint8 twothirds = scale8( offset8, (uint8)((256 * 2) / 3)); // max=170
						r = 171 - twothirds;
						g = 170 + third;
						b = 0;
					}
					if( Y2 ) {
						r = 255 - offset8;
						g = 255;
						b = 0;
					}
				} else {
					// 011
					// case 3: // G -> A
					r = 0;
					g = 255 - third;
					b = third;
				}
			}
		} else {
			// section 4-7
			// 1XX
			if( (hue & 0x40) == 0 ) {
				// 10X
				if( ( hue & 0x20) == 0 ) {
					// 100
					//case 4: // A -> B
					r = 0;
					//uint8 twothirds = (third << 1);
					uint8 twothirds = scale8( offset8, (uint8)((256 * 2) / 3)); // max=170
					g = 171 - twothirds; //170?
					b = 85  + twothirds;
					
				} else {
					// 101
					//case 5: // B -> P
					r = third;
					g = 0;
					b = 255 - third;
					
				}
			} else {
				if( (hue & 0x20) == 0 ) {
					// 110
					//case 6: // P -- K
					r = 85 + third;
					g = 0;
					b = 171 - third;
					
				} else {
					// 111
					//case 7: // K -> R
					r = 170 + third;
					g = 0;
					b = 85 - third;
					
				}
			}
		}
		
		// This is one of the good places to scale the green down,
		// although the client can scale green down as well.
		if( G2 ) g = g >> 1;
		if( Gscale > 0 ) g = scale8_video( g, Gscale);

		this.r = r * 257;
		this.g = g * 257;
		this.b = b * 257;
		
		// Scale down colors if we're desaturated at all
		// and add the brightness_floor to r, g, and b.
		if( sat != 255 ) {
			if( sat == 0) {
				this.r = 65535; this.b = 65535; this.g = 65535;
			} else {
				uint16 sat16 = sat * 257;
				uint16 desat16 = 65535 - sat16;
				desat16 = scale16_video( desat16, desat16);

				uint16 satscale = 65535 - desat16;
				//satscale = sat; // uncomment to revert to pre-2021 saturation behavior

				//nscale8x3_video( r, g, b, sat);
				this.r = scale16( this.r, satscale);
				this.g = scale16( this.g, satscale);
				this.b = scale16( this.b, satscale);
				
				uint16 brightness_floor = desat16;
				this.r += brightness_floor;
				this.g += brightness_floor;
				this.b += brightness_floor;
			}
		}
		
		// Now scale everything down if we're at value < 255.
		if( val != 255 ) {
			uint16 val16 = val * 257;
			val16 = scale16_video( val16, val16);
			if( val16 == 0 ) {
				this.r=0; this.g=0; this.b=0;
			} else {
				// nscale8x3_video( r, g, b, val);
				this.r = scale16( this.r, val16);
				this.g = scale16( this.g, val16);
				this.b = scale16( this.b, val16);
			}
		}
	}
}
