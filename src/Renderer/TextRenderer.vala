using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.TextRenderer : CairoRenderer, Jsonable {
	public string font { get; set; default = "DejaVuSans 8"; }
	public Color color { get; set; default = new Color.from_hsv( 0, 0, 200 ); }
	public bool markup { get; set; default = false; }
	public bool antialias { get; set; default = false; }
	public bool hint_metrics { get; set; default = true; }
	public uint8 hint_style { get; set; default = 0; }
	public float letter_spacing { get; set; default = 1; }
	
	public string text { get; set; default = "%k:%M "; }
	public bool time_format { get; set; default = true; }
	
	protected Color? last_color = null;
	protected string? last_str = null;
	protected int64 start_time = 0;
	
	construct {
		// update surface if some properties have changed
		this.notify["font"].connect(() => { this.last_str = null; });
		this.notify["color"].connect(() => { this.last_str = null; });
		this.notify["markup"].connect(() => { this.last_str = null; });
		this.notify["antialias"].connect(() => { this.last_str = null; });
		this.notify["hint-metrics"].connect(() => { this.last_str = null; });
		this.notify["hint-style"].connect(() => { this.last_str = null; });
		
		// change default values
		this.x_speed = 15;
		this.y_offset = 10;
	}
	
	public static string escape( string str ) {
		return str.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;");
	}
	
	protected override Cairo.ImageSurface? render_surface() {
		var time = new DateTime.now(Main.timezone);
		
		string str;
		if(this.time_format) {
			str = time.format(this.text).chug();
		}else{
			str = this.text;
		}
		
		if(str != this.last_str || this.last_color == null || !this.last_color.equal(this.color)) {
			this.last_str = str;
			this.last_color = this.color.clone();
			
			// create a context, size doesn't matter yet
			Cairo.ImageSurface mini_surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, 1, 1);
			Pango.Context mini_context = Pango.cairo_create_context(new Cairo.Context(mini_surface));
			
			// set font options
			Cairo.FontOptions options = new Cairo.FontOptions();
			options.set_antialias(this.antialias ? Cairo.Antialias.GRAY : Cairo.Antialias.NONE);
			options.set_hint_metrics(this.hint_metrics ? Cairo.HintMetrics.ON : Cairo.HintMetrics.OFF);
			options.set_hint_style(this.hint_style == 0 ? Cairo.HintStyle.NONE : this.hint_style == 1 ? Cairo.HintStyle.SLIGHT : this.hint_style == 2 ? Cairo.HintStyle.MEDIUM : Cairo.HintStyle.FULL);
			Pango.cairo_context_set_font_options(mini_context, options);
			
			// create a PangoLayout, set the font and text
			Pango.Layout layout = new Pango.Layout(mini_context);
			
			layout.set_font_description(Pango.FontDescription.from_string(this.font));
			
			if(this.markup) {
				layout.set_markup(str, -1);
			}else{
				layout.set_text(str, -1);
			}
			
			// set letter spacing
			unowned Pango.AttrList attrlist = layout.get_attributes() ?? new Pango.AttrList();
			attrlist.insert( Pango.attr_letter_spacing_new( (int) (this.letter_spacing * Pango.SCALE) ) );
			layout.set_attributes( attrlist );
			
			// get dimensions
			Pango.Rectangle text_extends;
			layout.get_pixel_extents( out text_extends, null );
			
			// create real image with correct size
			Cairo.ImageSurface surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, text_extends.width, text_extends.height);
			Cairo.Context context = new Cairo.Context(surface);
			
			// copy
			uint8 r,g,b;
			this.color.clone().set_hsv(null, null, 255).get_rgb(out r, out g, out b); // set max brightness
			context.set_source_rgba(r/255.0, g/255.0, b/255.0, 1);
			context.move_to(-text_extends.x,-text_extends.y);
			Pango.cairo_show_layout(context, layout);
			
			// apply brightness
			context.set_operator(Cairo.Operator.ATOP);
			context.rectangle(0, 0, text_extends.width, text_extends.height);
			uint8 v;
			this.color.get_hsv(null, null, out v);
			double brightness = v / 255.0;
			context.set_source_rgba(0,0,0,1-brightness);
			context.fill();
			
			// Save the image:
			// surface.write_to_png ("img.png");
			
			return surface;
		}else{
			return null;
		}
	}
	
}
