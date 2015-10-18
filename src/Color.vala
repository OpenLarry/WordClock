using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Color : GLib.Object {
	public uint8 r = 0;
	public uint8 g = 0;
	public uint8 b = 0;
	
	private uint16 h;
	private uint8 s;
	private uint8 v;
	
	const uint8 LOG_BASE = 10;
	
	/**
	 * Create a new instance for representing any colors
	 */
	public Color( ) {
		
	}
	
	/**
	 * Create a new instance for representing any colors
	 * @param red Red channel brightness
	 * @param green Green channel brightness
	 * @param blue Blue channel brightness
	 */
	public Color.from_rgb( uint8 r, uint8 g, uint8 b ) {
		this.r = r;
		this.g = g;
		this.b = b;
	}
	
	/**
	 * Create a new instance for representing any colors
	 * @param red Red channel brightness
	 * @param green Green channel brightness
	 * @param blue Blue channel brightness
	 */
	public Color.from_hsv( uint16 h, uint8 s, uint8 v ) {
		this.set_hsv(h,s,v);
	}
	
	public void set_hsv( uint16? h, uint8? s, uint8? v ) {
		if(h==null || s==null || v==null) this.to_hsv();
		
		this.h = h ?? this.h;
		this.h = this.h % 360;
		this.s = s ?? this.s;
		this.v = v ?? this.v;
		
		this.to_rgb();
	}
	
	public uint16[] get_hsv() {
		this.to_hsv();
		return { this.h, this.s, this.v };
	}
	
	/**
	 * Convert rgb to hsv values
	 * http://stackoverflow.com/a/14733008
	 */
	private void to_hsv() {
		uint8 rgbMin, rgbMax;

		rgbMin = uint8.min(this.r,uint8.min(this.g,this.b));
		rgbMax = uint8.max(this.r,uint8.max(this.g,this.b));

		this.v = rgbMax;
		if (this.v == 0)
		{
			this.h = 0;
			this.s = 0;
			return;
		}

		this.s = (uint8) (((uint16) 255) * (rgbMax - rgbMin) / this.v);
		if (this.s == 0)
		{
			this.h = 0;
			return;
		}

		if (rgbMax == this.r)
			this.h = 0 + 60 * (this.g - this.b) / (rgbMax - rgbMin);
		else if (rgbMax == this.g)
			this.h = 120 + 60 * (this.b - this.r) / (rgbMax - rgbMin);
		else
			this.h = 240 + 60 * (this.r - this.g) / (rgbMax - rgbMin);

	}
	
	/**
	 * Convert hsv to rgb values
	 * http://stackoverflow.com/a/14733008
	 */
	private void to_rgb() {
		uint8 region, fpart, p, q, t;
		
		if(this.s == 0) {
			this.r = this.g = this.b = v;
			return;
		}
		
		region = this.h / 60;
		fpart = (this.h - (region * 60)) * 4;
		
		p = (this.v * (255 - this.s)) >> 8;
		q = (this.v * (255 - ((this.s * fpart) >> 8))) >> 8;
		t = (this.v * (255 - ((this.s * (255 - fpart)) >> 8))) >> 8;
			
		switch(region) {
			case 0:
				this.r = this.v; this.g = t; this.b = p; break;
			case 1:
				this.r = q; this.g = this.v; this.b = p; break;
			case 2:
				this.r = p; this.g = this.v; this.b = t; break;
			case 3:
				this.r = p; this.g = q; this.b = this.v; break;
			case 4:
				this.r = t; this.g = p; this.b = this.v; break;
			default:
				this.r = this.v; this.g = p; this.b = q; break;
		}
		
		return;
	}
	
	/**
	 * Mixes this color with another, allows daisy chaining
	 * @param color The other color
	 * @param percent Mixing factor between 0 (this color) and 255 (param color)
	 * @return this color
	 */
	public Color mix_with( Color color, uint8 percent = 127 ) {
		this.r = (uint8) ( (((uint16) this.r)*(255-percent) + ((uint16) color.r)*percent) / 255 );
		this.g = (uint8) ( (((uint16) this.g)*(255-percent) + ((uint16) color.g)*percent) / 255 );
		this.b = (uint8) ( (((uint16) this.b)*(255-percent) + ((uint16) color.b)*percent) / 255 );
		
		return this;
	}
	
	public Color clone() {
		return new Color.from_rgb( this.r, this.g, this.b );
	}
	
	public Color add_hue( int16 h ) {
		this.to_hsv();
		
		this.h = (this.h + h) % 360;
		
		this.to_rgb();
		
		return this;
	}
	
	public Color add_hue_by_time( DateTime time, uint timespan ) {
		uint seconds = time.get_hour() * 60 * 60 + time.get_minute() * 60 + time.get_second();
		
		uint offset = 0;
		if( (360/timespan) > 1 ) {
			offset = 360 * time.get_microsecond() / timespan / 1000000;
		}
		
		return this.add_hue( (int16) (((seconds%timespan) * 360)/timespan + offset) );
	}
	
	public static bool get_mapping( GLib.Value value, GLib.Variant variant, void* user_data ) {
		uint16 h=0;
		uint8 s=0,v=0;
		variant.get_child(0, "q", out h);
		variant.get_child(1, "y", out s);
		variant.get_child(2, "y", out v);
		
		value.set_object( new Color.from_hsv(h,s,v) );
		
		return true;
	}
	
	public static GLib.Variant set_mapping( GLib.Value value, GLib.VariantType expected_type, void* user_data ) {
		Color color = (Color) value.get_object();
		color.to_hsv();
		
		return new GLib.Variant.tuple( { new GLib.Variant.uint16( color.h ), new GLib.Variant.byte( color.s ), new GLib.Variant.byte( color.v ) } );
	}
	
	
	private uint8 log_light( uint8 x ) {
		if(x == 255) return 255;
		else if(x == 0) return 0;
		//else return (uint) Math.floor(x * STEPS);
		else return (uint8) Math.floor(((Math.pow( LOG_BASE , x/255.0 ) - 1) / ( LOG_BASE - 1 )) * 255);
	}
	
	private uint8 log_light_inv( uint8 x ) {
		if(x == 255) return 255;
		else if(x == 0) return 0;
		else return (uint8) Math.floor( 255 * Math.log((LOG_BASE-1)*(x/255.0)+1)/Math.log(LOG_BASE) );
	}
}
