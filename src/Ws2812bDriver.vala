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
	
	private uint8[,,] leds;
	private uint8[] ports;
	
	/**
	 * New instance of WS2812b driver for controlling RGB-LEDs via framebuffer
	 * @param ports Used display ports
	 * @param leds Number of LEDs per strip
	 */
	public Ws2812bDriver( uint8[] ports, int leds, int fps ) {
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
			(1000000000000/fps
			/(this.fb_var.pixclock*(this.fb_var.left_margin+this.fb_var.xres+this.fb_var.right_margin+this.fb_var.hsync_len))
			-(this.fb_var.upper_margin+this.fb_var.yres+this.fb_var.lower_margin)); // 1000000000000/50/(208333*144)-122
		
		// put frambuffer settings
		ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOPUT_VSCREENINFO, &this.fb_var);
		GLib.assert(ret==0); GLib.debug("put screeninfo");
		
		this.ports = ports;
		
		// init LED array
		this.leds = new uint8[this.ports.length,leds,3];
		this.clearLEDs();
		
		// map framebuffer into memory
		this.fb = Posix.mmap(null, this.fb_var.xres_virtual * this.fb_var.yres_virtual * sizeof(uint16), Posix.PROT_READ|Posix.PROT_WRITE, Posix.MAP_SHARED, this.fd, 0);
		GLib.assert(this.fb!=null); GLib.debug("mmap framebuffer");
		
		this.clearFb();
		
		// unblank screen
		ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOBLANK, 0 /*FB_BLANK_UNBLANK const missing in vala*/);
		GLib.assert(ret==0); GLib.debug("unblank screen");
		
		this.encodeToFb(false);
	}
	
	/**
	 * Encode LED array into framebuffer LED timings
	 * @param bottom top or bottom part of framebuffer (for vsync)
	 */
	private void encodeToFb(bool bottom) {
		/*
		 * Every display pixel (16 bit) is _part_ of one WS2812b bit for all 16 LED strips
		 * Every WS2812b bit needs 6 pixels:
		 * - Pixel data 110000 = LED bit 0
		 * - Pixel data 111100 = LED bit 1
		 * One LED (3x8 bit) needs 3x8x6 - 2 = 142 pixels
		 */
		
		uint pos = (bottom) ? this.fb_var.xres * this.fb_var.yres : 0;
		
		// fill framebuffer, generate LED timings
		for(uint8 led=0; led<this.leds.length[1]; led++) {
			for(uint8 color=0; color<this.leds.length[2]; color++) {
				for(int8 bit=7; bit>=0; bit--) {
					uint16 pix = 0x0000;
					for(int strip=0; strip<this.leds.length[0]; strip++) {
						if((bool) this.leds[strip,led,color] & (1 << bit))
							pix |= (1 << this.ports[strip]);
					}
					
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
	private void clearFb() {
		for(uint i=0;i < this.fb_var.xres_virtual * this.fb_var.yres_virtual;i++) {
			this.fb[i] = 0x0000;
		}
	}
	
	/**
	 * Set LEDs to black
	 */
	public void clearLEDs() {
		for(int i=0;i<this.leds.length[0];i++) {
			for(int j=0;j<this.leds.length[1];j++) {
				for(int k=0;k<this.leds.length[2];k++) {
					this.leds[i,j,k] = 0;
				}
			}
		}
	}
	
	/**
	 * Set framerate
	 * @param fps Frames per second
	 */
	public void setFps( uint16 fps ) {
		// get frambuffer settings
		var ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOGET_VSCREENINFO, &this.fb_var);
		GLib.assert(ret==0); GLib.debug("got screeninfo");
		
		this.fb_var.vsync_len = (uint32)
			(1000000000000/fps
			/(this.fb_var.pixclock*(this.fb_var.left_margin+this.fb_var.xres+this.fb_var.right_margin+this.fb_var.hsync_len))
			-(this.fb_var.upper_margin+this.fb_var.yres+this.fb_var.lower_margin)); // 1000000000000/50/(208333*144)-122
		
		// put frambuffer settings
		ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOPUT_VSCREENINFO, &this.fb_var);
		GLib.assert(ret==0); GLib.debug("put screeninfo");
	}
	
	/**
	 * Start copying LED array into framebuffer on every vsync
	 */
	public int start( FrameRenderer renderer ) {
		bool bottom = true;
		int arg = 0;
		
		uint frame = 0;
		var timer = new GLib.Timer();
		timer.start();
		
		while(true) {
			this.encodeToFb(bottom);
			bottom = !bottom;
			
			renderer.render( this.leds );
			
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
		}
		
		return 0;
	}
} 