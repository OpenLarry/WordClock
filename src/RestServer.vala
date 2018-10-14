using WordClock;
using Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.RestServer : Soup.Server {
	private new uint16 port = 8080;
	
	private ArrayList<Soup.WebsocketConnection> hwinfo_connections = new ArrayList<Soup.WebsocketConnection>();
	private ArrayList<Soup.WebsocketConnection> lua_log_connections = new ArrayList<Soup.WebsocketConnection>();
	private ArrayList<Soup.WebsocketConnection> livestream_connections = new ArrayList<Soup.WebsocketConnection>();
	
	/**
	 * Creates a new HTTP REST server instance with JSON interface
	 * @param port Port number
	 */
	public RestServer( uint16 port = 8080 ) throws GLib.Error {
		debug("Starting REST server");
		
		this.port = port;
		
		this.add_handler("/", this.request);
		this.add_handler("/hwinfo", this.request); // try non-websocket request first
		
		this.add_early_handler("/update", this.update);
		
		this.add_websocket_handler("/hwinfo", null, null, this.request_hwinfo);
		this.add_websocket_handler("/lua-log", null, null, this.request_lua_log);
		this.add_websocket_handler("/livestream", null, null, this.request_livestream);
		this.connect_signals();
		
		this.listen_all(this.port, 0);
		
		debug("Server running");
	}
	
	private void connect_signals() {
		Main.hwinfo.gpios.foreach( (e) => {
			e.value.action.connect( () => {
				this.update_hwinfo("gpios",e.key,e.value);
				return false;
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
	
	private void update( Soup.Server server, Soup.Message msg, string path, HashTable<string,string>? query, Soup.ClientContext client) {
		debug("Request: %s %s (%s, %lli)", msg.method, path, msg.request_headers.get_content_type(null) ?? "none", msg.request_headers.get_content_length());
		
		msg.response_headers.append("Access-Control-Allow-Origin", "*");
		msg.response_headers.append("Access-Control-Allow-Headers", "accept, content-type");
		msg.response_headers.append("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE");
		
		switch(msg.method ) {
			case "OPTIONS":
				msg.set_status(200);
				
				debug("Response: %u (%s, %lli)", msg.status_code, msg.response_headers.get_content_type(null) ?? "none", msg.response_body.length);
				return;
			case "POST":
				msg.request_body.set_accumulate(false);
				int64 content_length = msg.request_headers.get_content_length();
				
				try{
					FirmwareUpdate firmware_update = new FirmwareUpdate();
					
					ulong body_signal = 0, chunk_signal = 0, finished_signal = 0;
					int64 size = 0;
					
					chunk_signal = msg.got_chunk.connect((chunk) => {
						try{
							firmware_update.write_chunk(chunk.get_as_bytes());
							size += chunk.length;
						} catch ( Error e ) {
							// disconnect signals, remove cyclic reference
							msg.disconnect(chunk_signal);
							msg.disconnect(body_signal);
							msg.disconnect(finished_signal);
							
							firmware_update.abort();
							msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
							try {
								firmware_update.wait_close();
							} catch ( Error e ) {
								msg.set_response("text/plain", Soup.MemoryUse.COPY, ("\n"+e.message).data);
							}
							msg.set_status(500);
							
							debug("Response: %u (%s, %lli)", msg.status_code, msg.response_headers.get_content_type(null) ?? "none", msg.response_body.length);
						}
					});
					
					body_signal = msg.got_body.connect(() => {
						if(content_length == size) {
							try{
								firmware_update.finish();
							} catch( Error e ) {
								msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
								msg.set_status(500);
							}
							try{
								firmware_update.wait_close();
								
								msg.set_response("text/plain", Soup.MemoryUse.COPY, "success".data);
								msg.set_status(200);
							} catch( Error e ) {
								msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
								msg.set_status(500);
							}
						}else{
							firmware_update.abort();
							msg.set_response("text/plain", Soup.MemoryUse.COPY, "Data too short!".data);
							msg.set_status(500);
						}
						
						debug("Response: %u (%s, %lli)", msg.status_code, msg.response_headers.get_content_type(null) ?? "none", msg.response_body.length);
					});
					
					finished_signal = msg.finished.connect(() => { 
						// disconnect signals, remove cyclic reference
						msg.disconnect(chunk_signal);
						msg.disconnect(body_signal);
						msg.disconnect(finished_signal);
					});
				} catch( Error e ) {
					// just close connection and abort file transfer
					try {
						client.steal_connection().close();
					} catch ( Error e ) {
						warning(e.message);
					}
				}
			break;
			default:
				msg.set_status(405);
				debug("Response: %u (%s, %lli)", msg.status_code, msg.response_headers.get_content_type(null) ?? "none", msg.response_body.length);
			break;
		}
	}
	
	private void request_hwinfo( Soup.Server server, Soup.WebsocketConnection connection, string path, Soup.ClientContext client) {
		debug("WebSocket request: %s", path);
		
		this.hwinfo_connections.add(connection);
		try {
			connection.send_text(JsonHelper.to_string(Main.hwinfo.to_json()));
		} catch ( Error e ) {
			warning(e.message);
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
						debug("WebSocket connection closed");
					}
				}
			} catch ( Error e ) {
				warning(e.message);
			}
		}
	}
	
	private void request_lua_log( Soup.Server server, Soup.WebsocketConnection connection, string path, Soup.ClientContext client) {
		debug("WebSocket request: %s", path);
		
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
					debug("WebSocket connection closed");
				}
			}
		}
	}
	
	private void request_livestream( Soup.Server server, Soup.WebsocketConnection connection, string path, Soup.ClientContext client) {
		debug("WebSocket request: %s", path);
		
		if(this.livestream_connections.size == 0) {
			Timeout.add(100, this.update_livestream);
		}
		this.livestream_connections.add(connection);
		
		connection.send_binary((Main.settings.objects["clockrenderer"] as ClockRenderer).dump_colors());		
	}
	
	private bool update_livestream() {
		if(this.livestream_connections.size > 0) {
			uint8[] data = (Main.settings.objects["clockrenderer"] as ClockRenderer).dump_colors();
			for(int i=0;i<this.livestream_connections.size;i++) {
				var con = this.livestream_connections[i];
				if(con.get_state() == Soup.WebsocketState.OPEN) {
					con.send_binary(data);
				}else{
					this.livestream_connections.remove(con);
					i--;
					debug("WebSocket connection closed");
				}
			}
		}
		
		return this.livestream_connections.size == 0 ? Source.REMOVE : Source.CONTINUE;
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
		if( msg.request_headers.header_contains("Upgrade","websocket") ) return;
		
		debug("Request: %s %s (%s, %lli)", msg.method, path, msg.request_headers.get_content_type(null) ?? "none", msg.request_headers.get_content_length());
		
		msg.response_headers.append("Access-Control-Allow-Origin", "*");
		msg.response_headers.append("Access-Control-Allow-Headers", "accept, content-type");
		msg.response_headers.append("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE");
		
		if(msg.method == "OPTIONS") {
			msg.set_status(200);
		}else if(path == "/") {
			switch(msg.method) {
				case "GET":
					msg.set_response("text/html", Soup.MemoryUse.COPY, @"<h1>WordClock $(Version.GIT_DESCRIBE)</h1>".data);
					msg.set_status(200);
				break;
				default:
					msg.set_status(405);
				break;
			}
		}else if( path.index_of("/hwinfo") == 0 ) {
			switch(msg.method) {
				case "GET":
					try{
						string data = JsonHelper.to_string(Main.hwinfo.to_json( path.substring(7) ));
						
						msg.set_response("application/json", Soup.MemoryUse.COPY, data.data);
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
						if(path.substring(17) == "/scan") {
							(Main.settings.objects["wirelessnetworks"] as WirelessNetworks).scan_networks.begin(1,5,(obj, res) => {
								try{
									string data = JsonHelper.to_string( (Main.settings.objects["wirelessnetworks"] as WirelessNetworks).scan_networks.end(res).to_json(path.substring(22)) );
									
									msg.set_response("application/json", Soup.MemoryUse.COPY, data.data);
									msg.set_status(200);
								} catch( Error e ) {
									msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
									msg.set_status(400);
								}
								this.unpause_message(msg);
								debug("Response (async): %u (%s, %lli)", msg.status_code, msg.response_headers.get_content_type(null) ?? "none", msg.response_body.length);
							});
							this.pause_message(msg);
							return;
						}else{
							string data = JsonHelper.to_string( (Main.settings.objects["wirelessnetworks"] as WirelessNetworks).get_networks().to_json(path.substring(17) ) );
							
							msg.set_response("application/json", Soup.MemoryUse.COPY, data.data);
							msg.set_status(200);
						}
					} catch( Error e ) {
						msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
						msg.set_status(400);
					}
				break;
				case "POST":
					try{
						if(path.substring(17) == "/reassociate") {
							(Main.settings.objects["wirelessnetworks"] as WirelessNetworks).reassociate();
							
							msg.set_response("application/json", Soup.MemoryUse.COPY, "true".data);
							msg.set_status(200);
						}else{
							WirelessNetwork network = new WirelessNetwork();
							network.from_json( JsonHelper.from_string( (string) msg.request_body.flatten().data ) );
							
							uint id = (Main.settings.objects["wirelessnetworks"] as WirelessNetworks).add_network(network);
							
							msg.set_response("application/json", Soup.MemoryUse.COPY, id.to_string().data);
							msg.set_status(200);
						}
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
							
							(Main.settings.objects["wirelessnetworks"] as WirelessNetworks).edit_network(id, network);
							
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
							(Main.settings.objects["wirelessnetworks"] as WirelessNetworks).remove_network(id);
							
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
		}else if( path.index_of("/systeminfo") == 0 ) {
			switch(msg.method) {
				case "GET":
					try{
						string data = JsonHelper.to_string( new SystemInfo().to_json(path.substring(11) ) );
						msg.set_response("application/json", Soup.MemoryUse.COPY, data.data);
						
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
		}else if( path.index_of("/signal/") == 0 && path.length > 8 ) {
			switch(msg.method) {
				case "POST":
					(Main.settings.objects["signalrouter"] as SignalRouter).trigger_signal( path.substring(8) );
					
					msg.set_response("application/json", Soup.MemoryUse.COPY, "true".data);
					msg.set_status(200);
				break;
				default:
					msg.set_status(405);
				break;
			}
		}else{
			msg.set_status(404);
		}
		
		debug("Response: %u (%s, %lli)", msg.status_code, msg.response_headers.get_content_type(null) ?? "none", msg.response_body.length);
	}
} 
