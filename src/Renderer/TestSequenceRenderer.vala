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
	private uint16 brightness = 1 << 8;
	private bool flicker = false;
	
	private bool last_flicker = false;
	
	private Cancellable? cancellable = null;
	
	public bool render_matrix( Color[,] leds_matrix ) {
		uint16 r,g,b;
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
		uint16 r,g,b;
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
		uint16 r,g,b;
		this.get_color( Part.DOTS, out r, out g, out b );
		
		foreach( Color led in leds_backlight ) {
			led.r = (!this.flicker || this.last_flicker) ? r : 0;
			led.g = (!this.flicker || this.last_flicker) ? g : 0;
			led.b = (!this.flicker || this.last_flicker) ? b : 0;
			this.last_flicker = !this.last_flicker;
		}
		
		return true;
	}
	
	private void get_color( Part part, out uint16 r, out uint16 g, out uint16 b ) {
		r = g = b = 0;
		if(part in this.part) {
			if(RGB.RED in this.color) r = this.brightness;
			if(RGB.GREEN in this.color) g = this.brightness;
			if(RGB.BLUE in this.color) b = this.brightness;
		}
	}
	
	public void register() {
		SignalRouter signalrouter = Main.settings.get<SignalRouter>();
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
		SignalRouter signalrouter = Main.settings.get<SignalRouter>();
		uint signalfunc = signalrouter.add_signal_func(/^buttonhandler,[0-2](-1)?$/, (id,sig) => {
			switch(sig) {
				case "buttonhandler,0":
					if(this.part == Part.MATRIX) this.part = Part.BACKLIGHT;
					else if(this.part == Part.BACKLIGHT) this.part = Part.DOTS;
					else if(this.part == Part.DOTS) this.part = Part.MATRIX | Part.BACKLIGHT | Part.DOTS;
					else this.part = Part.MATRIX;
				break;
				case "buttonhandler,1":
					if(this.color == RGB.RED) this.color = RGB.GREEN;
					else if(this.color == RGB.GREEN) this.color = RGB.BLUE;
					else if(this.color == RGB.BLUE) this.color = RGB.RED | RGB.GREEN | RGB.BLUE;
					else this.color = RGB.RED;
				break;
				case "buttonhandler,2":
					if(this.brightness == 1 << 15) this.brightness = uint16.MAX;
					else if(this.brightness == uint16.MAX) this.brightness = Ws2812bDriver.SUBFRAMEDIFF;
					else this.brightness <<= 1;
				break;
				case "buttonhandler,2-1":
					this.flicker = !this.flicker;
				break;
				default:
					return false;
			}
			return true; 
		}, true);
		
		yield Main.settings.get<ClockRenderer>().overwrite( { this }, { this }, { this }, this.cancellable);
		
		signalrouter.remove_signal_func(signalfunc);
		this.cancellable = null;
	}
}
