using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Color : GLib.Object {
	public uint8 r{  get; set; default = 0; }
	public uint8 g { get; set; default = 0; }
	public uint8 b { get; set; default = 0; }
	
	/**
	 * Creates a new instance for representing any colors
	 * @param red Red channel brightness
	 * @param green Green channel brightness
	 * @param blue Blue channel brightness
	 */
	public Color( uint8 red, uint8 green, uint8 blue ) {
		this.r = red;
		this.g = green;
		this.b = blue;
	}
	
	/**
	 * Mixes this color with another
	 * @param color The other color
	 * @param percent Mixing factor between 0 (this color) and 1 (param color)
	 * @return The mixed color
	 *
	public Color mix_with( Color color, double percent = 0.5 ) {
		return new Color (this.red*(1.0-percent) + color.red*percent,
		                   this.green*(1.0-percent) + color.green*percent,
		                   this.blue*(1.0-percent) + color.blue*percent);
	}*/
}
