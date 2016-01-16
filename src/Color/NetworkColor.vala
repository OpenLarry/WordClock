using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.NetworkColor : Color, Jsonable {
	public uint port { get; set; default = 1024; }
	
	private Socket sock;
	private SocketSource source;
	
	public NetworkColor() {
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
				try {
					uint8 buffer[4096];
					size_t read = s.receive (buffer);
					buffer[read] = 0; // null-terminate string
					
					uint8 r,g,b;
					if(((string) buffer).scanf("%hhu,%hhu,%hhu", out r, out g, out b) == 3) {
						this.set_rgb(r,g,b);
					}
				} catch (Error e) {
					stderr.printf (e.message);
				}
				
				return true;
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
