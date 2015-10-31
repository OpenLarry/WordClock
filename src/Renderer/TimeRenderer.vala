using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.TimeRenderer : GLib.Object, Serializable, ClockRenderable, MatrixRenderer, DotsRenderer {
	private FrontPanel frontpanel = new WestGermanFrontPanel();
	
	public Color background_color { get; set; default = new Color.from_hsv( 0, 0, 0 ); }
	public Color words_color { get; set; default =  new Color.from_hsv( 0, 255, 150 ); }
	public Color dots_background_color { get; set; default = new Color.from_hsv( 0, 0, 0 ); }
	public Color dots_color { get; set; default = new Color.from_hsv( 0, 255, 150 ); }
	
	public uint background_rotate { get; set; default = 0; }
	public uint words_rotate { get; set; default = 86400; }
	public uint dots_background_rotate { get; set; default = 0; }
	public uint dots_rotate { get; set; default = 86400; }
	
	public double fade_secs { get; set; default = 1.0; }
	
	public string frontpanel_name {
		owned get {
			return frontpanel.get_class().get_type().name();
		}
		set {
			this.frontpanel = (FrontPanel) Object.new( Type.from_name( value ) );
		}
	}
	
	/**
	 * Renders time
	 * @param leds Array of LED RGB values
	 * @return Continue
	 */
	public bool render_matrix( Color[,] leds_matrix ) {
		var time = new DateTime.now_local();
		
		// rotate hue by time
		Color background_color, words_color;
		if(this.background_rotate > 0) {
			background_color = this.background_color.clone().add_hue_by_time( time, this.background_rotate );
		}else{
			background_color = this.background_color;
		}
		if(this.words_rotate > 0) {
			words_color = this.words_color.clone().add_hue_by_time( time, this.words_rotate );
		}else{
			words_color = this.words_color;
		}
		
		// background
		for(int i=0;i<leds_matrix.length[0];i++) {
			for(int j=0;j<leds_matrix.length[1];j++) {
				leds_matrix[i,j].mix_with(background_color, 255);
			}
		}
		
		// words - smooth fading
		if(time.get_minute() % 5 == 4 && 60.0 - time.get_seconds() < this.fade_secs) {
			uint8 fade = (uint8) (((time.get_seconds() - 60 + this.fade_secs) / this.fade_secs)*256.0);
			
			var words_old = this.frontpanel.getTime((uint8) time.get_hour(),(uint8) time.get_minute());
			time = time.add_seconds(this.fade_secs);
			var words_new = this.frontpanel.getTime((uint8) time.get_hour(),(uint8) time.get_minute());
			
			var words_common = new HashSet<FrontPanel.WordPosition>();
			words_common.add_all(words_old);
			words_common.retain_all(words_new);
			
			words_old.remove_all( words_common );
			words_new.remove_all( words_common );
			
			foreach(var word in words_common) {
				for(int j=0;j<word.length;j++) {
					leds_matrix[word.x+j,word.y].mix_with(words_color, 255);
				}
			}
			
			foreach(var word in words_old) {
				for(int j=0;j<word.length;j++) {
					leds_matrix[word.x+j,word.y].mix_with(words_color, 255-fade);
				}
			}
			foreach(var word in words_new) {
				for(int j=0;j<word.length;j++) {
					leds_matrix[word.x+j,word.y].mix_with(words_color, fade);
				}
			}
		// words - static
		}else{
			var words = this.frontpanel.getTime((uint8) time.get_hour(),(uint8) time.get_minute());
			foreach(var word in words) {
				for(int j=0;j<word.length;j++) {
					leds_matrix[word.x+j,word.y].mix_with(words_color, 255);
				}
			}
		}
		
		
		return true;
	}
	
	public bool render_dots( Color[] leds_dots ) {
		var time = new DateTime.now_local();
		
		// rotate hue by time
		Color dots_background_color, dots_color;
		if(this.dots_background_rotate > 0) {
			dots_background_color = this.dots_background_color.clone().add_hue_by_time( time, this.dots_background_rotate );
		}else{
			dots_background_color = this.dots_background_color;
		}
		if(this.dots_rotate > 0) {
			dots_color = this.dots_color.clone().add_hue_by_time( time, this.dots_rotate );
		}else{
			dots_color = this.dots_color;
		}
		
		// smooth fading
		uint8 fade;
		if(60.0 - time.get_seconds() < this.fade_secs) {
			fade = (uint8) (((time.get_seconds() - 60 + this.fade_secs) / this.fade_secs)*256.0);
			time = time.add_seconds(this.fade_secs);
		}else{
			fade = 255;
		}
		
		// minutes
		for(int i=0;i<4;i++) {
			leds_dots[i].mix_with(dots_background_color, 255);
		}
		
		// dots
		switch(time.get_minute()%5) {
			case 0:
				leds_dots[0].mix_with(dots_color, 255-fade);
				leds_dots[1].mix_with(dots_color, 255-fade);
				leds_dots[2].mix_with(dots_color, 255-fade);
				leds_dots[3].mix_with(dots_color, 255-fade);
			break;
			case 1:
				leds_dots[0].mix_with(dots_color, fade);
			break;
			case 2:
				leds_dots[0].mix_with(dots_color, 255);
				leds_dots[1].mix_with(dots_color, fade);
			break;
			case 3:
				leds_dots[0].mix_with(dots_color, 255);
				leds_dots[1].mix_with(dots_color, 255);
				leds_dots[2].mix_with(dots_color, fade);
			break;
			case 4:
				leds_dots[0].mix_with(dots_color, 255);
				leds_dots[1].mix_with(dots_color, 255);
				leds_dots[2].mix_with(dots_color, 255);
				leds_dots[3].mix_with(dots_color, fade);
			break;
		}
		
		return true;
	}
}
