using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.GammaTestRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer, DotsRenderer, BacklightRenderer {
	public Color color_dark = new Color.from_hsv( 0, 0, 0 );
	public Color color_bright = new Color.from_hsv( 0, 0, 255 );
	
	public uint16 k = 0;
	
	
	public uint8[] get_fps_range() {
		return {25,25};
	}
	
	public bool render_matrix( Color[,] leds_matrix ) {
		this.k++;
		
		uint8 k = (uint8) (((this.k/25)%2 == 0) ? this.k % 25 : 25 - (this.k % 25));
		for(int i=0;i<leds_matrix.length[0];i++) {
			for(int j=0;j<leds_matrix.length[1];j++) {
				if(j<4) {
					leds_matrix[i,j].mix_with(this.color_dark, 255).mix_with(this.color_bright, (uint8) k*10+k/5);
				}else if(j<8) {
					leds_matrix[i,j].mix_with(this.color_dark, 255).mix_with(this.color_bright, (uint8) 255-k*10-k/5);
				}else if(j==8) {
					leds_matrix[i,j].mix_with(this.color_dark, 255);
				}else if(j>8) {
					leds_matrix[i,j].mix_with(this.color_dark, 255).mix_with(this.color_bright, (uint8) i*25+i/2);
				}
			}
		}
		
		return true;
	}
	
	public bool render_dots( Color[] leds_dots ) {
		for(int i=0;i<leds_dots.length;i++) {
			leds_dots[i].mix_with(this.color_dark, 255);
		}
		
		return true;
	}
	
	public bool render_backlight( Color[] leds_backlight ) {
		uint8 k = (uint8) (((this.k/25)%2 == 0) ? this.k % 25 : 25 - (this.k % 25));
		for(int i=0;i<leds_backlight.length;i++) {
			if(i%2 == 0) {
				leds_backlight[i].mix_with(this.color_dark, 255).mix_with(this.color_bright, (uint8) k*10+k/5);
			}else{
				leds_backlight[i].mix_with(this.color_dark, 255).mix_with(this.color_bright, (uint8) 255-k*10-k/5);
			}
		}
		
		return true;
	}
}
