using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.TestSequenceRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer, DotsRenderer, BacklightRenderer {
	[Flags]
	private enum RGB {
		RED,
		GREEN,
		BLUE
	}
	
	[Flags]
	private enum Part {
		MATRIX,
		BACKLIGHT,
		DOTS
	}
	
	private RGB color = RGB.RED | RGB.GREEN | RGB.BLUE;
	private Part part = Part.MATRIX | Part.BACKLIGHT | Part.DOTS;
	private uint8 brightness = 1;
	private bool flicker = false;
	
	private bool last_flicker = false;
	
	private Cancellable? cancellable = null;
	
	public bool render_matrix( Color[,] leds_matrix ) {
		uint8 r,g,b;
		this.get_color( Part.MATRIX, out r, out g, out b );
		
		this.last_flicker = !this.last_flicker;
		
		foreach( Color led in leds_matrix ) {
			led.r = (!this.flicker || this.last_flicker) ? r : 0;
			led.g = (!this.flicker || this.last_flicker) ? g : 0;
			led.b = (!this.flicker || this.last_flicker) ? b : 0;
			this.last_flicker = !this.last_flicker;
		}
		
		return true;
	}
	
	public bool render_dots( Color[] leds_dots ) {
		uint8 r,g,b;
		this.get_color( Part.BACKLIGHT, out r, out g, out b );
		
		foreach( Color led in leds_dots ) {
			led.r = (!this.flicker || this.last_flicker) ? r : 0;
			led.g = (!this.flicker || this.last_flicker) ? g : 0;
			led.b = (!this.flicker || this.last_flicker) ? b : 0;
			this.last_flicker = !this.last_flicker;
		}
		
		return true;
	}
	
	public bool render_backlight( Color[] leds_backlight ) {
		uint8 r,g,b;
		this.get_color( Part.DOTS, out r, out g, out b );
		
		foreach( Color led in leds_backlight ) {
			led.r = (!this.flicker || this.last_flicker) ? r : 0;
			led.g = (!this.flicker || this.last_flicker) ? g : 0;
			led.b = (!this.flicker || this.last_flicker) ? b : 0;
			this.last_flicker = !this.last_flicker;
		}
		
		return true;
	}
	
	private void get_color( Part part, out uint8 r, out uint8 g, out uint8 b ) {
		r = g = b = 0;
		if(part in this.part) {
			if(RGB.RED in this.color) r = this.brightness;
			if(RGB.GREEN in this.color) g = this.brightness;
			if(RGB.BLUE in this.color) b = this.brightness;
		}
	}
	
	public void register() {
		SignalRouter signalrouter = (Main.settings.objects["signalrouter"] as SignalRouter);
		signalrouter.add_signal_func(/^buttonhandler,012-1$/, (id,sig) => {
			this.toggle_test_sequence.begin();
			return true; 
		});
	}
	
	private async void toggle_test_sequence() {
		if(this.cancellable != null && !this.cancellable.is_cancelled()) {
			this.cancellable.cancel();
			return;
		}
		
		this.cancellable = new Cancellable();
		SignalRouter signalrouter = (Main.settings.objects["signalrouter"] as SignalRouter);
		uint signalfunc = signalrouter.add_signal_func(/^buttonhandler,[0-2](-1)?$/, (id,sig) => {
			switch(sig) {
				case "buttonhandler,0":
					if(this.part == (Part.MATRIX | Part.BACKLIGHT | Part.DOTS)) this.part = Part.MATRIX;
					else this.part <<= 1;
					if(this.part > (Part.MATRIX | Part.BACKLIGHT | Part.DOTS)) this.part = Part.MATRIX | Part.BACKLIGHT | Part.DOTS;
				break;
				case "buttonhandler,1":
					if(this.color == (RGB.RED | RGB.GREEN | RGB.BLUE)) this.color = RGB.RED;
					else this.color <<= 1;
					if(this.color > (RGB.RED | RGB.GREEN | RGB.BLUE)) this.color = RGB.RED | RGB.GREEN | RGB.BLUE;
				break;
				case "buttonhandler,2":
					if(this.brightness == 255) this.brightness = 1;
					else this.brightness += 127;
				break;
				case "buttonhandler,2-1":
					this.flicker = !this.flicker;
				break;
				default:
					return false;
			}
			return true; 
		}, true);
		
		yield (Main.settings.objects["clockrenderer"] as ClockRenderer).overwrite( { this }, { this }, { this }, this.cancellable);
		
		signalrouter.remove_signal_func(signalfunc);
		this.cancellable = null;
	}
}
