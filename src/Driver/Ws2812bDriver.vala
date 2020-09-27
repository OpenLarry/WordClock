using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Ws2812bDriver : LedDriver, Jsonable, SystemSensor {
	const string DEVICE = "/dev/fb0";
    const uint8 SUBBITS = 3;
    const uint8 SUBFRAMES = 1 << SUBBITS;
    
    const uint8 SUBFRAMEDIFF = (0xFF / SUBFRAMES) + 1;
    const uint16 MAXCHANNEL = 0xFFFF - SUBFRAMEDIFF;
    
    private uint8[] subframe_order;
	
	private int fd;
	private weak uint16 *fb;
	private weak uint32 *fb32;
	private weak Linux.Framebuffer.VarScreenInfo fb_var;
	
	private Color[,] leds;
	private uint8[] ports;
    private uint32[] port_bits;
    
    private uint fb_vtotal; // number of lines per vsync
    private uint fb_htotal; // number of dots per hsync
    
    private uint[] active_buffer = new uint[2];
    private uint8 buffer_prepared = 0;
    private uint8 buffer_count;
	
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
            sum >>= 8;
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
        
        this.port_bits = new uint32[this.ports.length];
        for(uint8 i=0;i<this.ports.length;i++) {
            this.port_bits[i] = 0x00010001 << this.ports[i];
        }
        
        this.subframe_order = new uint8[SUBFRAMES];
        for(uint8 i=0;i<SUBFRAMES;i++) {
            // https://stackoverflow.com/a/2602885
            uint8 b=i;
            b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
            b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
            b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
            this.subframe_order[i] = b >> (8-SUBBITS);
        }
	
		this.fd = Posix.open(DEVICE, Posix.O_RDWR);
		assert(this.fd>=0); debug("Framebuffer device opened");
		
		// blank screen - disabled because of driver bug
		// var ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOBLANK, 1 /*FB_BLANK_NORMAL const missing in vala*/);
		// assert(ret==0);
		
		// get frambuffer settings
		var ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOGET_VSCREENINFO, &this.fb_var);
		assert(ret==0);
		
		// timing
		this.fb_var.bits_per_pixel = 16; // 16 bits = min -> 16 strips
		this.fb_var.pixclock = 208333; // picoseconds -> 4,8Mhz / 6 bit per "real pixel" = 800khz
		this.fb_var.left_margin = 0;
		this.fb_var.right_margin = 1; // can not be 0
		this.fb_var.upper_margin = 1; // can not be 0
		this.fb_var.lower_margin = 1; // can not be 0
		this.fb_var.hsync_len = 1; // can not be 0
		this.fb_var.vsync_len = 1;
		
		// resolution
		this.fb_var.xres = 142; // [3 colors] x [8 bit] x [6 FB-bit per bit] - (2 bit hsync)
        this.fb_htotal = this.fb_var.left_margin+this.fb_var.xres+this.fb_var.right_margin+this.fb_var.hsync_len;
		this.fb_var.yres = (uint32) // 120 LEDs = min, but expand to maximum size
            (1000000000000 / this.fps / this.fb_var.pixclock / this.fb_htotal
            - (this.fb_var.upper_margin+this.fb_var.lower_margin+this.fb_var.vsync_len));
        this.fb_vtotal = this.fb_var.upper_margin+this.fb_var.yres+this.fb_var.lower_margin+this.fb_var.vsync_len;;
		
		// vsync
		this.fb_var.xres_virtual = this.fb_var.xres;
		this.fb_var.yres_virtual = this.fb_var.yres * 2;
		this.fb_var.xoffset = 0;
		this.fb_var.yoffset = 0;
        
        this.buffer_count = (uint8) ((this.fb_var.yres_virtual / this.fb_var.yres) * (this.fb_var.xres_virtual / this.fb_var.xres));
		
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
        
        // working with 32 bit integers is faster than 2x16 bit
        this.fb32 = (uint32*) this.fb;
	}
    
    /**
        * Adjust new buffer
        */
    private void prepare_buffer() {
        this.active_buffer[0] += this.fb_var.xres;
        if(this.active_buffer[0] >= this.fb_var.xres_virtual) {
            this.active_buffer[0] = 0;
            
            this.active_buffer[1] += this.fb_var.yres;
            if(this.active_buffer[1] >= this.fb_var.yres_virtual) {
                this.active_buffer[1] = 0;
            }
        }
        
        if(this.buffer_prepared < this.buffer_count) {
            this.encode_grid();
            this.buffer_prepared++;
        }
    }
    
    private void encode_grid() {
       uint frame_offset = this.framebuffer_offset();
        
       for(uint32 y = 0; y < this.fb_var.yres; y++) {
            for(uint32 x = 0; x < this.fb_var.xres; x++) {
                uint32 pos = frame_offset + y * this.fb_var.xres_virtual + x;
                this.fb[pos] = 0x0000;
            }
        }
        
        for(uint8 subframe = 0; subframe < SUBFRAMES; subframe++) {
            uint32 subframe_offset = this.framebuffer_offset(subframe);
            
            for(uint32 y = 0; y < this.leds.length[1]; y++) {
                for(uint32 x = 0; x < this.fb_var.xres; x++) {
                    uint32 pos = subframe_offset + y * this.fb_var.xres_virtual + x;
                    if(x % 6 == 0 || x % 6 == 1)
                        this.fb[pos] = 0xFFFF;
                }
            }
        }
    }
    
    
    private void finish_buffer() {
		// switch front- and backbuffer
		this.fb_var.xoffset = this.active_buffer[0];
		this.fb_var.yoffset = this.active_buffer[1];
		var ret = Posix.ioctl(this.fd, Linux.Framebuffer.FBIOPAN_DISPLAY, &this.fb_var);
		assert(ret==0);
    }
    
    private uint32 framebuffer_offset( uint8 subframe = 0 ) {
        return this.active_buffer[0] + (this.active_buffer[1] + (this.fb_vtotal * subframe / SUBFRAMES)) * this.fb_var.xres_virtual;
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
         
        this.prepare_buffer();
        
		uint[] pos = new uint[SUBFRAMES];
        for(uint8 subframe = 0; subframe < SUBFRAMES; subframe++) {
            //pos[subframe] = (this.framebuffer_offset(this.subframe_order[subframe]) + 2) / 2; // for uint32 framebuffer
            pos[subframe] = (this.framebuffer_offset(subframe) + 2) / 2; // for uint32 framebuffer
		}
        
        uint16[] channel = new uint16[this.leds.length[0]];
        
        for(uint8 led=0; led<this.leds.length[1]; led++) {
            for(uint8 color=0; color<3; color++) {
                for(int strip=0; strip<this.leds.length[0]; strip++) {
                    switch(color) {
                        case 0:
                            channel[strip] = this.leds[strip,led].g;
                        break;
                        case 1:
                            channel[strip] = this.leds[strip,led].r;
                        break;
                        case 2:
                            channel[strip] = this.leds[strip,led].b;
                        break;
                    }
                    channel[strip] += channel[strip] <= MAXCHANNEL ? SUBFRAMEDIFF / 2 : 0;
                }
                
                for(uint8 subframe = 0; subframe < SUBFRAMES; subframe++) {
                    // loop unrolling would decrease execution time by 10%
                    for(int8 bit=15; bit>8; bit--) {
                        uint32 pix = 0x00000000;
                        
                        // loop unrolling would decrease execution time by 25%
                        for(int strip=0; strip<this.leds.length[0]; strip++) {
                            if((channel[strip] & (1 << bit)) != 0)
                                pix |= this.port_bits[strip];
                        }
                        this.fb32[pos[subframe]] = pix;
                        pos[subframe] += 3;
                    }
                    { // bit = 8
                        uint32 pix = 0x00000000;
                        
                        // loop unrolling would decrease execution time by 25%
                        for(int strip=0; strip<this.leds.length[0]; strip++) {
                            if((channel[strip] & (1 << 8)) != 0)
                                pix |= this.port_bits[strip];
                            channel[strip] += channel[strip] <= MAXCHANNEL ? SUBFRAMEDIFF : 0;
                        }
                        this.fb32[pos[subframe]] = pix;
                        pos[subframe] += (color<2) ? 3 : 2; // TODO: xres_virtual
                    }
                }
            }
        }
        
        this.finish_buffer();
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
        
        var performance = new Timer();
        double render = 0, encode = 0;
		
		while(this.cancellable == null || !this.cancellable.is_cancelled()) {
            if(Main.in_debug_mode()) {
                performance.start();
                renderer.render();
                render += performance.elapsed();
            }else{
                renderer.render();
            }
			
			this.frame++;
			
			double time_diff = timer.elapsed() - last_time;
			if(time_diff >= 1 || (this.frame - last_frame) >= this.fps) {
				this.current_fps = (this.frame - last_frame) / time_diff;
                
                if(Main.in_debug_mode()) {
                    stdout.printf("Performance: utilization: %f%%, render: %f, encode: %f, fps: %f\r", (render+encode)*100/timer.elapsed(), render/this.frame, encode/this.frame, this.current_fps);
                    stdout.flush();
                }
                
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
            
            if(Main.in_debug_mode()) {
                performance.start();
                this.encode_to_fb();
                encode += performance.elapsed();
            }else{
                this.encode_to_fb();
            }
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