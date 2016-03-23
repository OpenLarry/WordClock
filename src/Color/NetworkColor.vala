using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.NetworkColor : Color, Jsonable {
	public uint port { get; set; default = 1024; }
	
	private Socket sock;
	private SocketSource source;
	
	construct {
		this.socket_connect();
	}
	
	~NetworkColor() {
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
					uint8 rgb[3];
					size_t read = s.receive(rgb);
					
					if(read == 3) {
						//stdout.printf("Received color: %u,%u,%u\n", rgb[0],rgb[1],rgb[2]);
						this.set_rgb(rgb[0],rgb[1],rgb[2]);
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
	
	public override Json.Node to_json( string path = "" ) throws JsonError {
		return Jsonable.default_to_json( this, path );
	}
	
	public override void from_json(Json.Node node, string path = "") throws JsonError {
		this.socket_disconnect();
		Jsonable.default_from_json( this, node, path );
		this.socket_connect();
	}
}
