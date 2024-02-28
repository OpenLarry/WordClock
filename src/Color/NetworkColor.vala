using WordClock;
using Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.NetworkColor : Color, Jsonable {
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
	private uint _port = 1024;
	
	private static TreeMap<uint,Socket> sockets = new TreeMap<int,Socket>();
	private static TreeMap<uint,SocketSource> sources = new TreeMap<int,SocketSource>();
	private static TreeMultiMap<uint,unowned NetworkColor> colors = new TreeMultiMap<int,unowned NetworkColor>();
	
	construct {
		this.socket_connect();
	}
	
	~NetworkColor() {
		this.socket_disconnect();
	}
	
	private void socket_connect() {
		if(sockets[this.port] == null) {
			debug("Open UDP port %u", this.port);
			try {
				sockets[this.port] = new Socket(SocketFamily.IPV6, SocketType.DATAGRAM, SocketProtocol.UDP);
				sockets[this.port].set_option(Posix.IPProto.IPV6, /* IPV6_V6ONLY mssing */ 26, 0);
				sockets[this.port].bind(new InetSocketAddress(new InetAddress.any(SocketFamily.IPV6), (uint16) this.port), true);
				
				// segmentation fault without casting! bug in glib?
				sources[this.port] = (SocketSource) sockets[this.port].create_source(IOCondition.IN);
				sources[this.port].set_callback( (sock) => {
					uint port = ((InetSocketAddress) sock.local_address).port;
					
					try {
						uint8 rgb[3] = {0};
						ssize_t read = sockets[port].receive(rgb);
						
						if(read == 3) {
							//stdout.printf("Received color: %u,%u,%u\n", rgb[0],rgb[1],rgb[2]);
							foreach(unowned NetworkColor color in colors[port])
								color.set_rgb(rgb[0],rgb[1],rgb[2]);
						}
					} catch (Error e) {
						warning(e.message);
					}
					
					return GLib.Source.CONTINUE;
				});
				
				
				sources[this.port].attach( MainContext.default() );
			} catch (Error e) {
				warning(e.message);
			}
		}
		colors[this.port] = this;
	}
	
	private void socket_disconnect() {
		colors.remove(this.port, this);
		
		if(colors[this.port].size == 0) {
			debug("Close UDP port %u", this.port);
			try {
				if(sources[this.port] != null) {
					sources[this.port].destroy();
					sources.unset(this.port);
				}else{
					warning("Could not destroy source");
				}
				if(sockets[this.port] != null) {
					sockets[this.port].close();
					sockets.unset(this.port);
				}else{
					warning("Could not close socket");
				}
			} catch (Error e) {
				warning(e.message);
			}
		}
	}
	
	public override Json.Node to_json( string path = "" ) throws JsonError {
		return Jsonable.default_to_json( this, path );
	}
	
	public override void from_json(Json.Node node, string path = "") throws JsonError {
		Jsonable.default_from_json( this, node, path );
	}
}
