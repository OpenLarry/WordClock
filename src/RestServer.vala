using WordClock;
using Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.RestServer : Soup.Server {
	const uint16 PORT = 8080;
	
	private ArrayList<Soup.WebsocketConnection> hwinfo_connections = new ArrayList<Soup.WebsocketConnection>();
	private ArrayList<Soup.WebsocketConnection> lua_log_connections = new ArrayList<Soup.WebsocketConnection>();
	
	private WirelessNetworks wirelessnetworks = new WirelessNetworks();
	
	/**
	 * Creates a new HTTP REST server instance with JSON interface
	 * @param port Port number
	 * @param control LEDControl object which parses the request
	 */
	public RestServer( ) throws GLib.Error {
		this.add_handler("/", request);
		
		this.add_websocket_handler("/hwinfo", null, null, this.request_hwinfo);
		this.add_websocket_handler("/lua-log", null, null, this.request_lua_log);
		this.connect_signals();
		
		this.listen_all(PORT, Soup.ServerListenOptions.IPV4_ONLY);
	}
	
	private void connect_signals() {
		Main.hwinfo.gpios.foreach( (e) => {
			e.value.action.connect( () => {
				this.update_hwinfo("gpios",e.key,e.value);
			});
			
			return true;
		});
		Main.hwinfo.lradcs.foreach( (e) => {
			e.value.update.connect( () => {
				this.update_hwinfo("lradcs",e.key,e.value);
			});
			
			return true;
		});
		Main.hwinfo.system.foreach( (e) => {
			e.value.update.connect( () => {
				this.update_hwinfo("system",e.key,e.value);
			});
			
			return true;
		});
		(Main.settings.objects["lua"] as Lua).message.connect(this.update_lua_log);
	}
	
	private void request_hwinfo( Soup.Server server, Soup.WebsocketConnection connection, string path, Soup.ClientContext client) {
		this.hwinfo_connections.add(connection);
		try {
			connection.send_text(JsonHelper.to_string(Main.hwinfo.to_json()));
		} catch ( Error e ) {
			stderr.printf("Error: %s\n", e.message);
		}
	}
	
	private void update_hwinfo(string group, string name, Jsonable obj) {
		if(this.hwinfo_connections.size > 0) {
			try {
				string json = "{\""+group+"\":{\""+name+"\":"+JsonHelper.to_string(obj.to_json())+"}}";
				
				for(int i=0;i<this.hwinfo_connections.size;i++) {
					var con = this.hwinfo_connections[i];
					if(con.get_state() == Soup.WebsocketState.OPEN) {
						con.send_text(json);
					}else{
						this.hwinfo_connections.remove(con);
						i--;
					}
				}
			} catch ( Error e ) {
				stderr.printf("Error: %s\n", e.message);
			}
		}
	}
	
	private void request_lua_log( Soup.Server server, Soup.WebsocketConnection connection, string path, Soup.ClientContext client) {
		this.lua_log_connections.add(connection);
		connection.send_text((Main.settings.objects["lua"] as Lua).get_log());
	}
	
	private void update_lua_log(string message) {
		if(this.lua_log_connections.size > 0) {
			for(int i=0;i<this.lua_log_connections.size;i++) {
				var con = this.lua_log_connections[i];
				if(con.get_state() == Soup.WebsocketState.OPEN) {
					con.send_text(message+"\n");
				}else{
					this.lua_log_connections.remove(con);
					i--;
				}
			}
		}
	}
	
	
	/**
	 * Callback method for requests from Soup.Server
	 * @param server Server instance
	 * @param msg Message instance
	 * @param path Requested path
	 * @param query Query parameters
	 * @param client Client instance
	 */
	private void request( Soup.Server server, Soup.Message msg, string path, HashTable<string,string>? query, Soup.ClientContext client) {
		msg.response_headers.append("Access-Control-Allow-Origin", "*");
		msg.response_headers.append("Access-Control-Allow-Headers", "accept, content-type");
		msg.response_headers.append("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE");
		
		if(msg.method == "OPTIONS") {
			msg.set_status(200);
			return;
		}
		
		if(path == "/") {
			switch(msg.method) {
				case "GET":
					msg.set_response("text/html", Soup.MemoryUse.COPY, @"<h1>WordClock $(Version.GIT_DESCRIBE)</h1>".data);
					msg.set_status(200);
				break;
				default:
					msg.set_status(405);
				break;
			}
		}else if( path.index_of("/settings") == 0 ) {
			switch(msg.method) {
				case "GET":
					try{
						string data = JsonHelper.to_string( Main.settings.to_json( path.substring(9) ) );
						msg.set_response("application/json", Soup.MemoryUse.COPY, data.data);
						
						msg.set_status(200);
					} catch( Error e ) {
						msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
						msg.set_status(400);
					}
				break;
				case "PUT":
					try{
						Main.settings.from_json( JsonHelper.from_string( (string) msg.request_body.flatten().data ), path.substring(9) );
						
						// save immediately if complete configuration is updated
						if(path.substring(9) == "") {
							Main.settings.save();
						}else{
							Main.settings.deferred_save();
						}
						
						msg.set_response("application/json", Soup.MemoryUse.COPY, "true".data);
						msg.set_status(200);
					} catch( Error e ) {
						msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
						msg.set_status(400);
					}
				break;
				default:
					msg.set_status(405);
				break;
			}
		}else if( path.index_of("/lua") == 0 ) {
			switch(msg.method) {
				case "GET":
					try{
						string data = (Main.settings.objects["lua"] as Lua).read_script();
						msg.set_response("text/plain", Soup.MemoryUse.COPY, data.data);
						
						msg.set_status(200);
					} catch( IOError.NOT_FOUND e ) {
						msg.set_response("text/plain", Soup.MemoryUse.COPY, "".data);
						msg.set_status(204);
					} catch( Error e ) {
						msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
						msg.set_status(400);
					}
				break;
				case "PUT":
					try{
						(Main.settings.objects["lua"] as Lua).write_script((string) msg.request_body.flatten().data);
						// (Main.settings.objects["lua"] as Lua).reset();
						(Main.settings.objects["lua"] as Lua).run();
						
						
						msg.set_response("text/plain", Soup.MemoryUse.COPY, "true".data);
						msg.set_status(200);
					} catch( Error e ) {
						msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
						msg.set_status(400);
					}
				break;
				default:
					msg.set_status(405);
				break;
			}
		}else if( path.index_of("/wirelessnetworks") == 0 ) {
			switch(msg.method) {
				case "GET":
					try{
						string data = JsonHelper.to_string( wirelessnetworks.get_networks().to_json(path.substring(13) ) );
						msg.set_response("application/json", Soup.MemoryUse.COPY, data.data);
						
						msg.set_status(200);
					} catch( Error e ) {
						msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
						msg.set_status(400);
					}
				break;
				case "POST":
					try{
						WirelessNetwork network = new WirelessNetwork();
						network.from_json( JsonHelper.from_string( (string) msg.request_body.flatten().data ) );
						
						uint id = wirelessnetworks.add_network(network);
						
						msg.set_response("application/json", Soup.MemoryUse.COPY, id.to_string().data);
						msg.set_status(200);
					} catch( Error e ) {
						msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
						msg.set_status(400);
					}
				break;
				case "PUT":
					try{
						uint id = 0;
						if(path.scanf("/wirelessnetworks/%u", out id) == 1) {
							WirelessNetwork network = new WirelessNetwork();
							network.from_json( JsonHelper.from_string( (string) msg.request_body.flatten().data ) );
							
							wirelessnetworks.edit_network(id, network);
							
							msg.set_response("application/json", Soup.MemoryUse.COPY, "true".data);
							msg.set_status(200);
						}else{
							msg.set_response("text/plain", Soup.MemoryUse.COPY, "Missing ID!".data);
							msg.set_status(400);
						}
					} catch( Error e ) {
						msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
						msg.set_status(400);
					}
				break;
				case "DELETE":
					try{
						uint id = 0;
						if(path.scanf("/wirelessnetworks/%u", out id) == 1) {
							wirelessnetworks.remove_network(id);
							
							msg.set_response("application/json", Soup.MemoryUse.COPY, "true".data);
							msg.set_status(200);
						}else{
							msg.set_response("text/plain", Soup.MemoryUse.COPY, "Missing ID!".data);
							msg.set_status(400);
						}
					} catch( Error e ) {
						msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
						msg.set_status(400);
					}
				break;
				default:
					msg.set_status(405);
				break;
			}
		}else{
			msg.set_status(404);
		}
	}
} 
