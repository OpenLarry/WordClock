using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Tpm2NetRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer, BacklightRenderer {
	public uint port { get; set; default = 65506; }
	
	private Socket sock;
	private SocketSource source;
	private uint8 dataframe[516];
	
	construct {
		this.socket_connect();
	}
	
	~Tpm2NetRenderer() {
		this.socket_disconnect();
	}
	
	private void socket_connect() {
		try {
			this.sock = new Socket(SocketFamily.IPV4, SocketType.DATAGRAM, SocketProtocol.UDP);
			this.sock.bind(new InetSocketAddress.from_string("0.0.0.0", this.port), true);
			
			this.source = sock.create_source(IOCondition.IN);
			this.source.set_callback( (s, cond) => {
				if(this.ref_count == 1) return GLib.Source.REMOVE;
				
				try {
					uint8 rgb[518];
					size_t read = s.receive(rgb);
					
					if(rgb[0] == 0x9C && rgb[1] == 0xDA) {
						lock(this.dataframe) {
							this.dataframe = rgb;
						}
					}
				} catch (Error e) {
					stderr.printf (e.message);
				}
				
				return GLib.Source.CONTINUE;
			});
			
			
			this.source.attach( MainContext.default() );
		} catch (Error e) {
			stderr.printf ("Error: %s\n", e.message);
		}
	}
	
	private void socket_disconnect() {
		try {
			if(this.source != null) this.source.destroy();
			if(this.sock != null) this.sock.close();
		} catch (Error e) {
			stderr.printf ("Error: %s\n", e.message);
		}
	}
	
	public bool render_matrix( Color[,] leds_matrix ) {
		lock(this.dataframe) {
			for(int i=0;i<leds_matrix.length[0];i++) {
				for(int j=0;j<leds_matrix.length[1];j++) {
					leds_matrix[i,j].set_rgb(this.dataframe[(j*leds_matrix.length[0]+i)*3+6],this.dataframe[(j*leds_matrix.length[0]+i)*3+7],this.dataframe[(j*leds_matrix.length[0]+i)*3+8]);
				}
			}
		}
		
		return true;
	}
	
	public bool render_backlight( Color[] leds_backlight ) {
		lock(this.dataframe) {
			for(int i=0;i<leds_backlight.length;i++) {
				leds_backlight[i].set_rgb(this.dataframe[i*3+336],this.dataframe[i*3+337],this.dataframe[i*3+338]);
			}
		}
		
		return true;
	}
}
