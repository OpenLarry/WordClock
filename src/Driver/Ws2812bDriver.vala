using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Ws2812bDriver : GLib.Object, LedDriver {
	const string DEVICE = "/dev/fb0";
	
	private int fd;
	private weak uint16 *fb;
	private weak Linux.Framebuffer.VarScreenInfo fb_var; 
	
	private GLib.Cancellable? cancellable;
	
	private uint8 fps = 25;
	private Color[,] leds;
	private uint8[] ports;
	
	/**
	 * New instance of WS2812b driver for controlling RGB-LEDs via framebuffer
	 * @param ports Used display ports
	 * @param leds Number of LEDs per strip
	 * @param cancellable Cancellable object to stop running driver
	 */
	public Ws2812bDriver( uint8[] ports, int leds, GLib.Cancellable? cancellable = null ) {
		this.cancellable = cancellable;
		this.ports = ports;
		
		this.fd = Posix.open(DEVICE, Posix.O_RDWR);
		GLib.assert(this.fd>=0); GLib.debug("device opened");
		
		// blank screen
		var ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOBLANK, 1 /*FB_BLANK_NORMAL const missing in vala*/);
		GLib.assert(ret==0); GLib.debug("blank screen");
		
		// get frambuffer settings
		ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOGET_VSCREENINFO, &this.fb_var);
		GLib.assert(ret==0); GLib.debug("got screeninfo");
		
		// resolution
		this.fb_var.xres = 142; // [3 colors] x [8 bit] x [6 FB-bit per bit] - (2 bit hsync)
		this.fb_var.yres = 120; // 120 LEDs = min
		
		// vsync
		this.fb_var.xres_virtual = 142;
		this.fb_var.yres_virtual = fb_var.yres*2;
		this.fb_var.xoffset = 0;
		this.fb_var.yoffset = fb_var.yres;
		
		// timing
		this.fb_var.bits_per_pixel = 16; // 16 bits = min -> 16 strips
		this.fb_var.pixclock = 208333; // picoseconds -> 4,8Mhz / 6 bit per "real pixel" = 800khz
		this.fb_var.left_margin = 0;
		this.fb_var.right_margin = 1; // can not be 0
		this.fb_var.upper_margin = 1; // can not be 0
		this.fb_var.lower_margin = 1; // can not be 0
		this.fb_var.hsync_len = 1; // can not be 0
		this.fb_var.vsync_len = (uint32)
			(1000000000000/this.fps
			/(this.fb_var.pixclock*(this.fb_var.left_margin+this.fb_var.xres+this.fb_var.right_margin+this.fb_var.hsync_len))
			-(this.fb_var.upper_margin+this.fb_var.yres+this.fb_var.lower_margin)); // 1000000000000/fps/(208333*144)-122
		
		// put frambuffer settings
		ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOPUT_VSCREENINFO, &this.fb_var);
		GLib.assert(ret==0); GLib.debug("put screeninfo");
		
		// init LED array
		this.leds = new Color[this.ports.length,leds];
		for(int i=0;i<this.leds.length[0];i++) {
			for(int j=0;j<this.leds.length[1];j++) {
				this.leds[i,j] = new Color();
			}
		}
		
		// map framebuffer into memory
		this.fb = Posix.mmap(null, this.fb_var.xres_virtual * this.fb_var.yres_virtual * sizeof(uint16), Posix.PROT_READ|Posix.PROT_WRITE, Posix.MAP_SHARED, this.fd, 0);
		GLib.assert(this.fb!=null); GLib.debug("mmap framebuffer");
		
		this.clear_fb();
		
		// unblank screen
		ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOBLANK, 0 /*FB_BLANK_UNBLANK const missing in vala*/);
		GLib.assert(ret==0); GLib.debug("unblank screen");
		
		this.encode_to_fb(false);
	}
	
	/**
	 * Encode LED color array into framebuffer LED timings
	 * @param bottom top or bottom part of framebuffer (for vsync, odd or even frame)
	 */
	private void encode_to_fb(bool bottom) {
		/*
		 * Each display pixel (16 bit) is _part_ of one WS2812b bit for all 16 LED strips
		 * Each WS2812b bit needs 6 pixels:
		 * - Pixel data 110000 = LED bit 0
		 * - Pixel data 111100 = LED bit 1
		 * One LED (3x8 bit) needs 3x8x6 - 2 = 142 pixels
		 */
		
		uint pos = (bottom) ? this.fb_var.xres * this.fb_var.yres : 0;
		
		// fill framebuffer, generate LED timings
		for(uint8 led=0; led<this.leds.length[1]; led++) {
			for(uint8 color=0; color<3; color++) {
				for(int8 bit=7; bit>=0; bit--) {
					uint16 pix = 0x0000;
					for(int strip=0; strip<this.leds.length[0]; strip++) {
						
						// green, red, blue
						uint8 channel = 0;
						switch(color) {
							case 0:
								channel = this.leds[strip,led].g;
							break;
							case 1:
								channel = this.leds[strip,led].r;
							break;
							case 2:
								channel = this.leds[strip,led].b;
							break;
						}
						
						// encode bit
						if((bool) channel & (1 << bit))
							pix |= (1 << this.ports[strip]);
					}
					
					// 6 pixels = 1 bit for 16 LEDs
					this.fb[pos++] = 0xffff;
					this.fb[pos++] = 0xffff;
					this.fb[pos++] = pix;
					this.fb[pos++] = pix;
					
					// the last two pixels (00) of each display row are omitted, because hsync sets data bus to 0
					if(color<2 || bit>0) { // end of line = hsync 
						this.fb[pos++] = 0x0000;
						this.fb[pos++] = 0x0000;
					}
				}
			}
		}
		
		// switch front- and backbuffer
		this.fb_var.yoffset = (bottom) ? this.fb_var.yres : 0;
		var ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOPAN_DISPLAY, &this.fb_var);
		GLib.assert(ret==0); GLib.debug("pan display");
	}
	
	/**
	 * Clear framebuffer
	 */
	private void clear_fb() {
		for(uint i=0;i < this.fb_var.xres_virtual * this.fb_var.yres_virtual;i++) {
			this.fb[i] = 0x0000;
		}
	}
	
	/**
	 * Set framerate.
	 * Avoid this function if driver is running, results in weird vsync buffering.
	 * @param fps Frames per second
	 */
	public void set_fps( uint8 fps ) {
		if(this.fps == fps) return;
		
		this.fps = fps;
		
		// get frambuffer settings
		var ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOGET_VSCREENINFO, &this.fb_var);
		GLib.assert(ret==0); GLib.debug("got screeninfo");
		
		this.fb_var.vsync_len = (uint32)
			(1000000000000/fps
			/(this.fb_var.pixclock*(this.fb_var.left_margin+this.fb_var.xres+this.fb_var.right_margin+this.fb_var.hsync_len))
			-(this.fb_var.upper_margin+this.fb_var.yres+this.fb_var.lower_margin)); // 1000000000000/fps/(208333*144)-122
		
		// put frambuffer settings
		ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOPUT_VSCREENINFO, &this.fb_var);
		GLib.assert(ret==0); GLib.debug("put screeninfo");
	}
	
	/**
	 * Start copying LED color array into framebuffer on every vsync
	 * @param renderer Active frame renderer
	 * @return Result code
	 */
	public int start( FrameRenderer renderer ) {
		bool bottom = true;
		int arg = 0;
		
		uint frame = 0;
		var timer = new GLib.Timer();
		timer.start();
		
		var cont = true;
		
		while(cont && !this.cancellable.is_cancelled()) {
			cont = renderer.render( this.leds );
			
			if(timer.elapsed() > 1) {
				stdout.printf("%u fps\n", frame);
				frame = 0;
				timer.start();
			}else{
				frame++;
			}
			
			// wait for vsync
			var ret = Posix.ioctl(this.fd, 1074021920 /*FBIO_WAITFORVSYNC const missing in vala*/, &arg);
			GLib.assert(ret==0); GLib.debug("wait for vsync");
			
			this.encode_to_fb(bottom);
			bottom = !bottom;
		}
		
		if(this.cancellable.is_cancelled()) {
			this.clear_fb();
			
			// blank screen
			var ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOBLANK, 1 /*FB_BLANK_NORMAL const missing in vala*/);
			GLib.assert(ret==0); GLib.debug("blank screen");
		}
		
		return 0;
	}
} 