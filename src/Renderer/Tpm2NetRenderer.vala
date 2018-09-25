using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Tpm2NetRenderer : GLib.Object, Jsonable, ClockRenderable, MatrixRenderer, BacklightRenderer {
	public uint port {
		get {
			return this._port;
		}
		set {
			if(value == this._port) return;
			this.socket_disconnect();
			this._port = value;
			this.socket_connect();
		}
	}
	private uint _port = 65506;
	
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
		debug("Open UDP port %u", this.port);
		try {
			this.sock = new Socket(SocketFamily.IPV6, SocketType.DATAGRAM, SocketProtocol.UDP);
			this.sock.set_option(Posix.IPProto.IPV6, /* IPV6_V6ONLY mssing */ 26, 0);
			this.sock.bind(new InetSocketAddress(new InetAddress.any(SocketFamily.IPV6), (uint16) this.port), true);
			
			// segmentation fault without casting! bug in glib?
			this.source = (SocketSource) sock.create_source(IOCondition.IN);
			this.source.set_callback( () => {
				if(this.ref_count == 1) return GLib.Source.REMOVE;
				
				try {
					uint8 rgb[518];
					this.sock.receive(rgb);
					
					if(rgb[0] == 0x9C && rgb[1] == 0xDA) {
						lock(this.dataframe) {
							this.dataframe = rgb;
						}
					}
				} catch (Error e) {
					warning(e.message);
				}
				
				return GLib.Source.CONTINUE;
			});
			
			
			this.source.attach( MainContext.default() );
		} catch (Error e) {
			warning(e.message);
		}
	}
	
	private void socket_disconnect() {
		debug("Close UDP port %u", this.port);
		try {
			if(this.source != null) this.source.destroy();
			if(this.sock != null) this.sock.close();
		} catch (Error e) {
			warning(e.message);
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
