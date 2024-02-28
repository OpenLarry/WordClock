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
	
	protected uint8 h = 0;
	protected uint8 s = 0;
	protected uint8 v = 0;
	
	protected uint last_update_frame = uint.MAX;
	
	/**
	 * Create a new instance for representing any colors
	 * @param h Color hue
	 * @param s Color saturation
	 * @param v Color value (brightness)
	 */
	 public Color.from_hsv( uint8 h, uint8 s, uint8 v ) {
		this.set_hsv(h, s, v);
	}
	
	/**
	 * Create a new instance for representing any colors
	 * @param r Red channel brightness
	 * @param g Green channel brightness
	 * @param b Blue channel brightness
	 */
	public Color.from_rgb( uint8 r, uint8 g, uint8 b ) {
		this.set_rgb(r, g, b);
	}

	public Color set_hsv( uint8? h, uint8? s, uint8? v ) {
		this.h = h ?? this.h;
		this.s = s ?? this.s;
		this.v = v ?? this.v;

		this.to_rgb();
		return this;
	}
	
	public Color set_rgb( uint8? r, uint8? g, uint8? b ) {
		if(r != null) this.r = r << 8;
		if(g != null) this.g = g << 8;
		if(b != null) this.b = b << 8;
		
		this.to_hsv();
		this.to_rgb();
		return this;
	}

	public Color set_rgb16( uint16? r, uint16? g, uint16? b ) {
		this.r = r ?? this.r;
		this.g = g ?? this.g;
		this.b = b ?? this.b;
		
		this.to_hsv();
		this.to_rgb();
		return this;
	}

	public void get_hsv( out uint8 h, out uint8 s, out uint8 v, bool check_update = true ) {
		if(check_update) this.check_update();
		h = this.h;
		s = this.s;
		v = this.v;
	}
	
	public void get_rgb( out uint8 r, out uint8 g, out uint8 b, bool check_update = true ) {
		uint16 lr, lg, lb;
		get_rgb16(out lr, out lg, out lb, check_update);
		r = (uint8) (lr >> 8);
		g = (uint8) (lg >> 8);
		b = (uint8) (lb >> 8);
	}
	
	public void get_rgb16( out uint16 r, out uint16 g, out uint16 b, bool check_update = true ) {
		if(check_update) this.check_update();
		r = this.r;
		g = this.g;
		b = this.b;
	}

	protected virtual void update(uint framediff) {}
	protected void check_update() {
		uint frame = ((LedDriver) Main.hwinfo.system["leddriver"]).frame;
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
	public Color mix_with( Color color, uint8 percent = 127 ) {
		if(percent == 0) {
			this.check_update();
		}else if(percent == 255) {
			color.check_update();

			this.r = color.r;
			this.g = color.g;
			this.b = color.b;
			this.h = color.h;
			this.s = color.s;
			this.v = color.v;

			this.last_update_frame = color.last_update_frame;
		}else{
			color.check_update();
			this.check_update();

			// keep hue the same when saturation or value is zero
			if(this.s == 0 && color.s != 0 || this.v == 0 && color.v != 0)
				this.h = color.h;

			if(this.s != 0 && color.s != 0 && this.v != 0 && color.v != 0)
			{
				int8 hdiff = (int8) (color.h - this.h);
				this.h = this.h + (hdiff * percent / 255);
			}

			this.s = (uint8) ( (((uint16) this.s)*(255-percent) + ((uint16) color.s)*percent) / 255 );
			this.v = (uint8) ( (((uint16) this.v)*(255-percent) + ((uint16) color.v)*percent) / 255 );
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
			this.r = (uint16) ( (((uint32) this.r)*(255-percent) + ((uint16) r << 8)*percent) / 255 );
			this.g = (uint16) ( (((uint32) this.g)*(255-percent) + ((uint16) g << 8)*percent) / 255 );
			this.b = (uint16) ( (((uint32) this.b)*(255-percent) + ((uint16) b << 8)*percent) / 255 );
			this.to_hsv();
			this.to_rgb();
		}
		
		return this;
	}
	
	public Color clone() {
		this.check_update();
		
		var ret = new Color();
		
		ret.r = this.r;
		ret.g = this.g;
		ret.b = this.b;
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

	protected void to_hsv() {
		uint8 r = (uint8) (this.r >> 8);
		uint8 g = (uint8) (this.g >> 8);
		uint8 b = (uint8) (this.b >> 8);

		uint8 rgbMin = uint8.min(r,uint8.min(g,b));
		uint8 rgbMax = uint8.max(r,uint8.max(g,b));

		this.v = rgbMax;
		if (this.v == 0) {
			this.h = 0;
			this.s = 0;
			return;
		}

		this.s = (uint8) (255 * (rgbMax - rgbMin) / this.v);
		if (this.s == 0) {
			this.h = 0;
			return;
		}

		if (rgbMax == r) {
			if( g > b )
				this.h = 0 + 64 * (g - b) / (rgbMax - rgbMin);
			else
				this.h = 0 + 48 * (g - b) / (rgbMax - rgbMin);
		}else if (rgbMax == g) {
			if( b > r )
				this.h = 96 + 40 * (b - r) / (rgbMax - rgbMin);
			else
				this.h = 96 + 32 * (b - r) / (rgbMax - rgbMin);
		}else{
			if( r > g )
				this.h = 160 + 48 * (r - g) / (rgbMax - rgbMin);
			else
				this.h = 160 + 24 * (r - g) / (rgbMax - rgbMin);
		}
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
					this.set_hsv( (uint8) node.get_int(), null, null );
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
			
			uint8? h = null, s = null, v = null;
			if(obj.has_member("h")) h = (uint8) obj.get_int_member( "h" );
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

	private void to_rgb() {
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
		
		uint8 offset = this.h & 0x1F; // 0..31
		
		// offset8 = offset * 8
		uint8 offset8 = offset;
		// On ARM and other non-AVR platforms, we just shift 3.
		offset8 <<= 3;
		
		uint8 third = scale8( offset8, (uint8)(256 / 3)); // max = 85
		
		uint8 r=0, g=0, b=0;
		
		if( (this.h & 0x80) == 0 ) {
			// 0XX
			if( (this.h & 0x40) == 0 ) {
				// 00X
				//section 0-1
				if( (this.h & 0x20) == 0 ) {
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
				if( (this.h & 0x20) == 0 ) {
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
			if( (this.h & 0x40) == 0 ) {
				// 10X
				if( ( this.h & 0x20) == 0 ) {
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
				if( (this.h & 0x20) == 0 ) {
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

		this.r = r << 8;
		this.g = g << 8;
		this.b = b << 8;
		
		// Scale down colors if we're desaturated at all
		// and add the brightness_floor to r, g, and b.
		if( this.s != 255 ) {
			if( this.s == 0) {
				this.r = 0xFF00; this.b = 0xFF00; this.g = 0xFF00;
			} else {
				uint16 sat16 = this.s << 8;
				uint16 desat16 = 0xFF00 - sat16;
				desat16 = scale16_video( desat16, desat16);

				uint16 satscale = 0xFF00 - desat16;
				//satscale = this.s; // uncomment to revert to pre-2021 saturation behavior

				//nscale8x3_video( r, g, b, this.s);
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
		if( this.v != 255 ) {
			uint16 val16 = this.v << 8;
			val16 = scale16_video( val16, val16);
			if( val16 == 0 ) {
				this.r=0; this.g=0; this.b=0;
			} else {
				// nscale8x3_video( r, g, b, this.v);
				this.r = scale16( this.r, val16);
				this.g = scale16( this.g, val16);
				this.b = scale16( this.b, val16);
			}
		}
	}
}
