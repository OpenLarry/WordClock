using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Ws2812bDriver : LedDriver, Jsonable, SystemSensor {
	const string DEVICE = "/dev/fb0";
	
	private int fd;
	private weak uint16 *fb;
	private weak Linux.Framebuffer.VarScreenInfo fb_var;
	
	private Color[,] leds;
	private uint8[] ports;
	private bool bottom = false;
	
	/**
	 * power consumption in watts
	 */
	public float power_consumption {
		get {
			uint sum = 0;
			for(int i=0;i<this.leds.length[0];i++) {
				for(int j=0;j<this.leds.length[1];j++) {
					sum += this.leds[i,j].r;
					sum += this.leds[i,j].g;
					sum += this.leds[i,j].b;
				}
			}
			return 0.00000000087198f * sum * sum + 0.00037150f * sum + 2.8f;
		}
	}
	
	/**
	 * New instance of WS2812b driver for controlling RGB-LEDs via framebuffer
	 * @param ports Used display ports
	 * @param leds Number of LEDs per strip
	 * @param cancellable Cancellable object to stop running driver
	 */
	public Ws2812bDriver( uint8[] ports, int leds, Cancellable? cancellable = null ) {
		base(cancellable);
		
		this.ports = ports;
		
		this.fd = Posix.open(DEVICE, Posix.O_RDWR);
		assert(this.fd>=0); debug("Framebuffer device opened");
		
		// blank screen - disabled because of driver bug
		// var ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOBLANK, 1 /*FB_BLANK_NORMAL const missing in vala*/);
		// assert(ret==0);
		
		// get frambuffer settings
		var ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOGET_VSCREENINFO, &this.fb_var);
		assert(ret==0);
		
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
		assert(ret==0);
		
		// init LED array
		this.leds = new Color[this.ports.length,leds];
		for(int i=0;i<this.leds.length[0];i++) {
			for(int j=0;j<this.leds.length[1];j++) {
				this.leds[i,j] = new Color();
			}
		}
		
		// map framebuffer into memory
		this.fb = Posix.mmap(null, this.fb_var.xres_virtual * this.fb_var.yres_virtual * sizeof(uint16), Posix.PROT_READ|Posix.PROT_WRITE, Posix.MAP_SHARED, this.fd, 0);
		assert(this.fb!=null);
	}
	
	/**
	 * Encode LED color array into framebuffer LED timings
	 */
	private void encode_to_fb() {
		/*
		 * Each display pixel (16 bit) is _part_ of one WS2812b bit for all 16 LED strips
		 * Each WS2812b bit needs 6 pixels:
		 * - Pixel data 110000 = LED bit 0
		 * - Pixel data 111100 = LED bit 1
		 * One LED (3x8 bit) needs 3x8x6 - 2 = 142 pixels
		 */
		
		// bottom top or bottom part of framebuffer (for vsync, odd or even frame)
		uint pos = (this.bottom) ? this.fb_var.xres * this.fb_var.yres : 0;
		
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
		this.fb_var.yoffset = (this.bottom) ? this.fb_var.yres : 0;
		var ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOPAN_DISPLAY, &this.fb_var);
		assert(ret==0);
		
		this.bottom = !this.bottom;
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
	public override void set_fps( uint8 fps ) {
		if(this.fps == fps) return;
		
		debug("Set fps rate to %u", fps);
		
		this.fps = fps;
		
		// get frambuffer settings
		var ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOGET_VSCREENINFO, &this.fb_var);
		assert(ret==0);
		
		this.fb_var.vsync_len = (uint32)
			(1000000000000/fps
			/(this.fb_var.pixclock*(this.fb_var.left_margin+this.fb_var.xres+this.fb_var.right_margin+this.fb_var.hsync_len))
			-(this.fb_var.upper_margin+this.fb_var.yres+this.fb_var.lower_margin)); // 1000000000000/fps/(208333*144)-122
		
		// put frambuffer settings
		ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOPUT_VSCREENINFO, &this.fb_var);
		assert(ret==0);
	}
	
	/**
	 * Start copying LED color array into framebuffer on every vsync
	 * @param renderer Active frame renderer
	 * @return Result code
	 */
	public override int start( FrameRenderer renderer ) {
		renderer.set_leds( this.leds );
		
		int arg = 0;
		
		var timer = new Timer();
		double last_time = 0;
		uint last_frame = 0;
		timer.start();
		
		while(this.cancellable == null || !this.cancellable.is_cancelled()) {
			renderer.render();
			
			this.frame++;
			
			double time_diff = timer.elapsed() - last_time;
			if(time_diff >= 1 || (this.frame - last_frame) >= this.fps) {
				this.current_fps = (this.frame - last_frame) / time_diff;
				last_time += time_diff;
				last_frame = this.frame;
				
				// call update function in main thread, need to save time here!
				Idle.add(() => {
					this.update();
					return Source.REMOVE;
				});
			}
			
			// wait for vsync
			var ret = Posix.ioctl(this.fd, 1074021920 /*FBIO_WAITFORVSYNC const missing in vala*/, &arg);
			assert(ret==0);
			
			this.encode_to_fb();
		}
		
		this.current_fps = 0;
		// call update function in main thread, need to safe time here!
		Idle.add(() => {
			this.update();
			return Source.REMOVE;
		});
		
		// black screen
		for(int i=0;i<this.leds.length[0];i++) {
			for(int j=0;j<this.leds.length[1];j++) {
				this.leds[i,j].set_hsv(0,0,0);
			}
		}
		
		// wait for vsync - start render previous frame
		var ret = Posix.ioctl(this.fd, 1074021920 /*FBIO_WAITFORVSYNC const missing in vala*/, &arg);
		assert(ret==0);
		
		this.encode_to_fb();
		
		// wait for vsync - start render black frame
		ret = Posix.ioctl(this.fd, 1074021920 /*FBIO_WAITFORVSYNC const missing in vala*/, &arg);
		assert(ret==0);
		
		// wait for vsync - finished render black frame
		ret = Posix.ioctl(this.fd, 1074021920 /*FBIO_WAITFORVSYNC const missing in vala*/, &arg);
		assert(ret==0);
		
		this.clear_fb();
		
		// blank screen - disabled because of driver bug
		// var ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOBLANK, 1 /*FB_BLANK_NORMAL const missing in vala*/);
		// assert(ret==0);
			
		return 0;
	}
} 